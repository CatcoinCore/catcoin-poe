import pytest
from datetime import datetime, timedelta
from sqlalchemy.future import select

import models
from services.session_manager import SessionManager, EarningsManager


class TestSessionCompletion:
    """Test session completion logic"""
    
    @pytest.mark.asyncio
    async def test_complete_expired_session(self, db_session, expired_mining_session, test_user):
        """Test that expired sessions are completed correctly"""
        # Verify session is expired but not completed
        assert expired_mining_session.status == models.MiningStatus.ACTIVE
        assert expired_mining_session.completed_at is None
        assert expired_mining_session.end_time < datetime.utcnow()
        
        # Complete expired sessions
        completed = await SessionManager.complete_expired_sessions(test_user.id, db_session)
        
        # Verify session was completed
        assert len(completed) == 1
        assert completed[0].id == expired_mining_session.id
        assert completed[0].status == models.MiningStatus.COMPLETED
        assert completed[0].completed_at is not None
        assert completed[0].total_earned > 0
        
        # Verify user balance updated
        await db_session.refresh(test_user)
        assert test_user.balance > 0
        assert abs(test_user.balance - completed[0].total_earned) < 0.00001
    
    @pytest.mark.asyncio
    async def test_complete_session_calculates_earnings_correctly(
        self, db_session, test_user, test_admin_config
    ):
        """Test earnings calculation is correct"""
        # Create a session with known duration
        now = datetime.utcnow()
        duration_seconds = 3600  # 1 hour
        
        session = models.MiningSession(
            user_id=test_user.id,
            session_type=models.SessionType.BASE,
            start_time=now - timedelta(seconds=duration_seconds + 60),
            end_time=now - timedelta(seconds=60),
            status=models.MiningStatus.ACTIVE,
            reward_y=1000,
            reward_t=1,
        )
        db_session.add(session)
        await db_session.commit()
        
        # Complete session
        completed = await SessionManager.complete_expired_sessions(test_user.id, db_session)

        assert len(completed) == 1
        elapsed = int((session.end_time - session.start_time).total_seconds())
        expected_earnings = (elapsed * session.reward_y) // session.reward_t
        assert completed[0].total_earned == expected_earnings
    
    @pytest.mark.asyncio
    async def test_idempotent_completion(self, db_session, expired_mining_session, test_user):
        """Test that completing sessions multiple times doesn't create duplicates"""
        # Complete once
        completed_first = await SessionManager.complete_expired_sessions(test_user.id, db_session)
        first_balance = test_user.balance
        first_earned = completed_first[0].total_earned
        
        # Complete again
        completed_second = await SessionManager.complete_expired_sessions(test_user.id, db_session)
        
        # Verify no new completions
        assert len(completed_second) == 0
        
        # Verify balance didn't change
        await db_session.refresh(test_user)
        assert test_user.balance == first_balance
    
    @pytest.mark.asyncio
    async def test_active_sessions_not_completed(self, db_session, test_mining_session, test_user):
        """Test that active (not expired) sessions are not completed"""
        # Try to complete sessions
        completed = await SessionManager.complete_expired_sessions(test_user.id, db_session)
        
        # Verify no sessions completed
        assert len(completed) == 0
        
        # Verify session still active
        await db_session.refresh(test_mining_session)
        assert test_mining_session.status == models.MiningStatus.ACTIVE
        assert test_mining_session.completed_at is None


class TestDailyLedgerAggregation:
    """Test daily ledger aggregation"""
    
    @pytest.mark.asyncio
    async def test_creates_daily_ledger_entry(self, db_session, expired_mining_session, test_user):
        """Test that completing sessions creates daily ledger entry"""
        today = datetime.utcnow().date()
        
        # Complete session
        await SessionManager.complete_expired_sessions(test_user.id, db_session)
        
        # Check ledger entry exists
        result = await db_session.execute(
            select(models.EarningsLedger)
            .where(models.EarningsLedger.user_id == test_user.id)
            .where(models.EarningsLedger.aggregation_date == today)
            .where(models.EarningsLedger.reward_type == models.RewardType.MINING_BASE)
        )
        ledger = result.scalars().first()
        
        assert ledger is not None
        assert ledger.amount > 0
        assert ledger.aggregation_date == today
    
    @pytest.mark.asyncio
    async def test_aggregates_multiple_sessions(self, db_session, test_user, test_admin_config):
        """Test that multiple sessions are aggregated into one daily entry"""
        now = datetime.utcnow()
        today = now.date()
        
        # Create 3 expired sessions
        sessions = []
        for i in range(3):
            session = models.MiningSession(
                user_id=test_user.id,
                session_type=models.SessionType.BASE,
                start_time=now - timedelta(hours=5+i),
                end_time=now - timedelta(hours=1+i),
                status=models.MiningStatus.ACTIVE,
                reward_y=1000,
                reward_t=1,
            )
            db_session.add(session)
            sessions.append(session)
        await db_session.commit()
        
        # Complete all sessions
        completed = await SessionManager.complete_expired_sessions(test_user.id, db_session)
        assert len(completed) == 3
        
        # Check only ONE ledger entry exists for today
        result = await db_session.execute(
            select(models.EarningsLedger)
            .where(models.EarningsLedger.user_id == test_user.id)
            .where(models.EarningsLedger.aggregation_date == today)
            .where(models.EarningsLedger.reward_type == models.RewardType.MINING_BASE)
        )
        ledgers = result.scalars().all()
        
        assert len(ledgers) == 1
        
        # Verify ledger amount equals sum of sessions
        total_earned = sum(s.total_earned for s in completed)
        assert abs(ledgers[0].amount - total_earned) < 0.00001
    
    @pytest.mark.asyncio
    async def test_separate_entries_for_base_and_boost(
        self, db_session, test_user, test_admin_config
    ):
        """Test BASE and REFERRAL_BOOST sessions create separate ledger entries"""
        now = datetime.utcnow()
        today = now.date()
        
        # Create BASE session
        base_session = models.MiningSession(
            user_id=test_user.id,
            session_type=models.SessionType.BASE,
            start_time=now - timedelta(hours=5),
            end_time=now - timedelta(hours=1),
            status=models.MiningStatus.ACTIVE,
            reward_y=1000,
            reward_t=1,
        )
        db_session.add(base_session)
        
        # Create REFERRAL_BOOST session
        boost_session = models.MiningSession(
            user_id=test_user.id,
            session_type=models.SessionType.REFERRAL_BOOST,
            start_time=now - timedelta(hours=5),
            end_time=now - timedelta(hours=1),
            status=models.MiningStatus.ACTIVE,
            reward_y=500,
            reward_t=1,
        )
        db_session.add(boost_session)
        await db_session.commit()
        
        # Complete sessions
        await SessionManager.complete_expired_sessions(test_user.id, db_session)
        
        # Check TWO ledger entries exist
        result = await db_session.execute(
            select(models.EarningsLedger)
            .where(models.EarningsLedger.user_id == test_user.id)
            .where(models.EarningsLedger.aggregation_date == today)
        )
        ledgers = result.scalars().all()
        
        assert len(ledgers) == 2
        
        # Verify both types exist
        reward_types = {ledger.reward_type for ledger in ledgers}
        assert models.RewardType.MINING_BASE in reward_types
        assert models.RewardType.MINING_REFERRAL_BOOST in reward_types


class TestLedgerSessionMapping:
    """Test ledger-session mapping (junction table)"""
    
    @pytest.mark.asyncio
    async def test_creates_mapping_entries(self, db_session, expired_mining_session, test_user):
        """Test that completing session creates mapping entry"""
        # Complete session
        completed = await SessionManager.complete_expired_sessions(test_user.id, db_session)
        
        # Check mapping exists
        result = await db_session.execute(
            select(models.LedgerSessionMapping)
            .where(models.LedgerSessionMapping.session_id == expired_mining_session.id)
        )
        mapping = result.scalars().first()
        
        assert mapping is not None
        assert mapping.session_contribution == completed[0].total_earned
    
    @pytest.mark.asyncio
    async def test_mapping_links_to_ledger(self, db_session, expired_mining_session, test_user):
        """Test that mapping correctly links session to ledger entry"""
        today = datetime.utcnow().date()
        
        # Complete session
        await SessionManager.complete_expired_sessions(test_user.id, db_session)
        
        # Get ledger entry
        result = await db_session.execute(
            select(models.EarningsLedger)
            .where(models.EarningsLedger.user_id == test_user.id)
            .where(models.EarningsLedger.aggregation_date == today)
        )
        ledger = result.scalars().first()
        
        # Get mapping
        result = await db_session.execute(
            select(models.LedgerSessionMapping)
            .where(models.LedgerSessionMapping.session_id == expired_mining_session.id)
        )
        mapping = result.scalars().first()
        
        # Verify link
        assert mapping.ledger_entry_id == ledger.id
    
    @pytest.mark.asyncio
    async def test_session_unique_constraint(self, db_session, expired_mining_session, test_user):
        """Test that same session can't be added to ledger twice"""
        # Complete once
        await SessionManager.complete_expired_sessions(test_user.id, db_session)
        
        # Try to create duplicate mapping manually
        from sqlalchemy.exc import IntegrityError
        
        await db_session.refresh(expired_mining_session)
        assert expired_mining_session.ledger_entry_id is not None

        duplicate_mapping = models.LedgerSessionMapping(
            ledger_entry_id=expired_mining_session.ledger_entry_id,
            session_id=expired_mining_session.id,
            session_contribution=10.0,
        )
        db_session.add(duplicate_mapping)
        
        with pytest.raises(IntegrityError):
            await db_session.commit()


class TestBalanceVerification:
    """Test balance calculations and verification"""
    
    @pytest.mark.asyncio
    async def test_balance_equals_ledger_sum(self, db_session, test_user, test_admin_config):
        """Test that user balance equals sum of all ledger entries"""
        now = datetime.utcnow()
        
        # Create multiple sessions
        for i in range(5):
            session = models.MiningSession(
                user_id=test_user.id,
                session_type=models.SessionType.BASE,
                start_time=now - timedelta(hours=10+i),
                end_time=now - timedelta(hours=1+i),
                status=models.MiningStatus.ACTIVE,
                reward_y=1000,
                reward_t=1,
            )
            db_session.add(session)
        await db_session.commit()
        
        # Complete all
        await SessionManager.complete_expired_sessions(test_user.id, db_session)
        
        # Get ledger sum
        from sqlalchemy import func
        result = await db_session.execute(
            select(func.sum(models.EarningsLedger.amount))
            .where(models.EarningsLedger.user_id == test_user.id)
        )
        ledger_total = result.scalar() or 0.0
        
        # Verify balance matches
        await db_session.refresh(test_user)
        assert abs(test_user.balance - ledger_total) < 0.00001
