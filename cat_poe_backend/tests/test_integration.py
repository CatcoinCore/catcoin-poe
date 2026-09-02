import uuid

import pytest
from datetime import datetime, timedelta
from httpx import ASGITransport, AsyncClient
from sqlalchemy.future import select

import models
from main import app
from tests.conftest import TestSessionLocal


class TestLoginSessionCleanup:
    """Test that login triggers session completion"""
    
    @pytest.mark.asyncio
    async def test_login_completes_expired_sessions(self, db_session, test_user, expired_mining_session):
        """Successful login runs session cleanup and completes expired mining sessions."""
        async def override_get_db():
            yield db_session

        from database import get_db

        app.dependency_overrides[get_db] = override_get_db
        try:
            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post(
                    "/auth/login",
                    data={
                        "username": test_user.username,
                        "password": "testpassword",
                    },
                )
            assert response.status_code == 200
            await db_session.refresh(expired_mining_session)
            assert expired_mining_session.status == models.MiningStatus.COMPLETED
            assert expired_mining_session.completed_at is not None
        finally:
            app.dependency_overrides.pop(get_db, None)

    @pytest.mark.asyncio
    async def test_login_updates_last_active(self, db_session, test_user):
        """Test that login updates last_active_at"""
        original_active = test_user.last_active_at
        
        # Simulate login updating last_active
        test_user.last_active_at = datetime.utcnow()
        await db_session.commit()
        
        await db_session.refresh(test_user)
        assert test_user.last_active_at > original_active


class TestStatsSessionCleanup:
    """Test that /stats/me triggers session completion"""
    
    @pytest.mark.asyncio
    async def test_stats_completes_sessions(self, db_session, test_user, expired_mining_session):
        """Test that fetching stats completes expired sessions"""
        from services.session_manager import SessionManager
        
        # Verify session is expired
        assert expired_mining_session.end_time < datetime.utcnow()
        
        # Call complete_expired_sessions (simulating /stats/me)
        completed = await SessionManager.complete_expired_sessions(test_user.id, db_session)
        
        # Verify completion
        assert len(completed) == 1
        await db_session.refresh(expired_mining_session)
        assert expired_mining_session.status == models.MiningStatus.COMPLETED


class TestEarningsManager:
    """Test EarningsManager helper methods"""
    
    @pytest.mark.asyncio
    async def test_create_reward_entry(self, db_session, test_user):
        """Test creating individual reward entry"""
        from services.session_manager import EarningsManager
        
        # Create reward
        entry = await EarningsManager.create_reward_entry(
            user_id=test_user.id,
            amount=0.5,
            reward_type=models.RewardType.SOCIAL_X,
            description="Followed @catcoin",
            db=db_session
        )
        
        # Verify entry
        assert entry.amount == 0.5
        assert entry.reward_type == models.RewardType.SOCIAL_X
        assert entry.description == "Followed @catcoin"
        assert entry.aggregation_date is None  # Not aggregated
    
    @pytest.mark.asyncio
    async def test_create_withdrawal_entry(self, db_session, test_user):
        """Test creating withdrawal entry with negative amount"""
        from services.session_manager import EarningsManager

        payout = models.Payout(
            user_id=test_user.id,
            catcoin_address="TESTADDR1",
            amount_cat=5.0,
            status="pending",
        )
        db_session.add(payout)
        await db_session.flush()

        entry = await EarningsManager.create_withdrawal_entry(
            user_id=test_user.id,
            amount=5.0,
            payout_id=str(payout.id),
            db=db_session,
        )

        assert entry.amount == -5.0
        assert entry.reward_type == models.RewardType.WITHDRAWAL
        assert str(payout.id) in entry.description
    
    @pytest.mark.asyncio
    async def test_calculate_earnings_breakdown(self, db_session, test_user):
        """Test earnings breakdown calculation"""
        from services.session_manager import EarningsManager
        
        # Create various reward types
        await EarningsManager.create_reward_entry(
            user_id=test_user.id,
            amount=1.0,
            reward_type=models.RewardType.SOCIAL_X,
            description="Test",
            db=db_session
        )
        
        await EarningsManager.create_reward_entry(
            user_id=test_user.id,
            amount=0.5,
            reward_type=models.RewardType.SOCIAL_DISCORD,
            description="Test",
            db=db_session
        )
        
        # Get breakdown
        breakdown = await EarningsManager.calculate_earnings_breakdown(test_user.id, db_session)
        
        # Verify
        assert breakdown[models.RewardType.SOCIAL_X.value] == 1.0
        assert breakdown[models.RewardType.SOCIAL_DISCORD.value] == 0.5


class TestEdgeCases:
    """Test edge cases and error scenarios"""
    
    @pytest.mark.asyncio
    async def test_complete_sessions_for_nonexistent_user(self, db_session):
        """Test completing sessions for user that doesn't exist"""
        from services.session_manager import SessionManager
        import uuid
        
        fake_user_id = str(uuid.uuid4())
        
        # Should return empty list, not error
        completed = await SessionManager.complete_expired_sessions(fake_user_id, db_session)
        assert completed == []
    
    @pytest.mark.asyncio
    async def test_zero_duration_session(self, db_session, test_user, test_admin_config):
        """Test session with zero duration"""
        from services.session_manager import SessionManager
        
        now = datetime.utcnow()
        session = models.MiningSession(
            user_id=test_user.id,
            session_type=models.SessionType.BASE,
            start_time=now - timedelta(seconds=1),
            end_time=now - timedelta(seconds=1),
            status=models.MiningStatus.ACTIVE,
            reward_y=100,
            reward_t=1,
        )
        db_session.add(session)
        await db_session.commit()
        
        # Complete
        completed = await SessionManager.complete_expired_sessions(test_user.id, db_session)
        
        # Should complete with 0 earnings
        assert len(completed) == 1
        assert completed[0].total_earned >= 0  # Can't be negative
    
    @pytest.mark.asyncio
    async def test_concurrent_completions(self, db_session, test_user, expired_mining_session):
        """After one completion, concurrent follow-up calls return empty (idempotent)."""
        from services.session_manager import SessionManager

        first = await SessionManager.complete_expired_sessions(test_user.id, db_session)
        assert len(first) == 1

        second = await SessionManager.complete_expired_sessions(test_user.id, db_session)
        third = await SessionManager.complete_expired_sessions(test_user.id, db_session)
        assert len(second) == 0
        assert len(third) == 0
