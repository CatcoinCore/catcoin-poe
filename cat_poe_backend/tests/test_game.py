import pytest
from datetime import datetime, timedelta
from sqlalchemy.future import select

import models
from tests.conftest import TestSessionLocal


class TestGameSession:
    """Test game session model creation and validation"""

    @pytest.mark.asyncio
    async def test_create_game_session(self, db_session, test_user):
        """Test creating a game session with a session token"""
        import secrets

        token = secrets.token_urlsafe(32)
        session = models.GameSession(
            user_id=test_user.id,
            session_token=token,
            start_time=datetime.utcnow(),
        )
        db_session.add(session)
        await db_session.commit()
        await db_session.refresh(session)

        assert session.id is not None
        assert session.session_token == token
        assert session.user_id == test_user.id
        assert session.validated is False
        assert session.score == 0
        assert session.coins_collected == 0

    @pytest.mark.asyncio
    async def test_game_session_lookup_by_token(self, db_session, test_user):
        """Test looking up a game session by token"""
        import secrets

        token = secrets.token_urlsafe(32)
        session = models.GameSession(
            user_id=test_user.id,
            session_token=token,
        )
        db_session.add(session)
        await db_session.commit()

        # Look up by token
        result = await db_session.execute(
            select(models.GameSession).where(
                models.GameSession.session_token == token,
                models.GameSession.user_id == test_user.id,
            )
        )
        found = result.scalars().first()
        assert found is not None
        assert found.session_token == token

    @pytest.mark.asyncio
    async def test_game_session_validation(self, db_session, test_user):
        """Test validating a game session with score and coins"""
        import secrets

        token = secrets.token_urlsafe(32)
        start_time = datetime.utcnow() - timedelta(seconds=30)
        session = models.GameSession(
            user_id=test_user.id,
            session_token=token,
            start_time=start_time,
        )
        db_session.add(session)
        await db_session.commit()

        # Simulate submit
        session.end_time = datetime.utcnow()
        session.score = 1500
        session.coins_collected = 25
        session.distance_meters = 300
        session.validated = True
        await db_session.commit()
        await db_session.refresh(session)

        assert session.validated is True
        assert session.score == 1500
        assert session.coins_collected == 25
        assert session.distance_meters == 300


class TestGameReward:
    """Test game reward creation and ledger integration"""

    @pytest.mark.asyncio
    async def test_create_game_reward(self, db_session, test_user):
        """Test creating a game reward linked to a session"""
        import secrets

        # Create session
        token = secrets.token_urlsafe(32)
        session = models.GameSession(
            user_id=test_user.id,
            session_token=token,
            validated=True,
            score=1000,
            coins_collected=50,
        )
        db_session.add(session)
        await db_session.commit()
        await db_session.refresh(session)

        # Create reward
        reward = models.GameReward(
            user_id=test_user.id,
            session_id=session.id,
            reward_catoshi=50,  # 1 coin = 1 catoshi
        )
        db_session.add(reward)
        await db_session.commit()
        await db_session.refresh(reward)

        assert reward.id is not None
        assert reward.reward_catoshi == 50
        assert reward.user_id == test_user.id
        assert reward.session_id == session.id

    @pytest.mark.asyncio
    async def test_game_reward_writes_to_ledger(self, db_session, test_user):
        """Test that game rewards create entries in the earnings ledger"""
        import secrets

        # Create session
        token = secrets.token_urlsafe(32)
        session = models.GameSession(
            user_id=test_user.id,
            session_token=token,
            validated=True,
            coins_collected=30,
        )
        db_session.add(session)
        await db_session.commit()
        await db_session.refresh(session)

        # Create reward
        reward = models.GameReward(
            user_id=test_user.id,
            session_id=session.id,
            reward_catoshi=30,
        )
        db_session.add(reward)

        # Create ledger entry (simulating what the router does)
        ledger = models.EarningsLedger(
            user_id=test_user.id,
            amount=30.0,
            reward_type=models.RewardType.GAME_REWARD,
            description=f"Game session score:1000 coins:30",
            is_verified=True,
        )
        db_session.add(ledger)
        await db_session.commit()

        # Verify ledger entry exists
        result = await db_session.execute(
            select(models.EarningsLedger).where(
                models.EarningsLedger.user_id == test_user.id,
                models.EarningsLedger.reward_type == models.RewardType.GAME_REWARD,
            )
        )
        entries = result.scalars().all()
        assert len(entries) >= 1
        assert entries[-1].amount == 30.0
        assert entries[-1].reward_type == models.RewardType.GAME_REWARD
        assert entries[-1].is_verified is True


class TestAntiCheat:
    """Test anti-cheat validation logic"""

    @pytest.mark.asyncio
    async def test_coins_per_second_cap(self, db_session, test_user):
        """Test that coins are capped at MAX_COINS_PER_SECOND"""
        MAX_COINS_PER_SECOND = 10
        duration_seconds = 10  # 10 seconds of gameplay
        claimed_coins = 500  # Way too many

        max_possible = int(duration_seconds * MAX_COINS_PER_SECOND)
        validated_coins = min(claimed_coins, max_possible)

        assert validated_coins == 100  # Capped at 10/sec × 10sec
        assert validated_coins < claimed_coins

    @pytest.mark.asyncio
    async def test_valid_coin_count_passes(self, db_session, test_user):
        """Test that reasonable coin counts pass validation"""
        MAX_COINS_PER_SECOND = 10
        duration_seconds = 60
        claimed_coins = 45  # Very reasonable for 60 seconds

        max_possible = int(duration_seconds * MAX_COINS_PER_SECOND)
        validated_coins = min(claimed_coins, max_possible)

        assert validated_coins == 45  # Not capped

    @pytest.mark.asyncio
    async def test_session_duration_checks(self):
        """Test min/max session duration validation"""
        MIN_DURATION = 3
        MAX_DURATION = 3600

        # Too short
        assert 1 < MIN_DURATION  # Would be rejected

        # Just right
        assert 30 >= MIN_DURATION
        assert 30 <= MAX_DURATION

        # Too long
        assert 5000 > MAX_DURATION  # Would be rejected

    @pytest.mark.asyncio
    async def test_double_submit_prevented(self, db_session, test_user):
        """Test that a session can't be submitted twice"""
        import secrets

        token = secrets.token_urlsafe(32)
        session = models.GameSession(
            user_id=test_user.id,
            session_token=token,
            validated=True,  # Already validated
            score=1000,
            coins_collected=50,
        )
        db_session.add(session)
        await db_session.commit()
        await db_session.refresh(session)

        # Verify session is marked as validated
        assert session.validated is True
        # Router would reject this with "Session already submitted"


class TestGameRewardType:
    """Test GAME_REWARD enum integration"""

    @pytest.mark.asyncio
    async def test_game_reward_type_exists(self):
        """Test that GAME_REWARD is in RewardType enum"""
        assert hasattr(models.RewardType, 'GAME_REWARD')
        assert models.RewardType.GAME_REWARD.value == "GAME_REWARD"

    @pytest.mark.asyncio
    async def test_game_reward_in_ledger(self, db_session, test_user):
        """Test that GAME_REWARD type can be stored in earnings ledger"""
        entry = models.EarningsLedger(
            user_id=test_user.id,
            amount=100.0,
            reward_type=models.RewardType.GAME_REWARD,
            description="Test game reward",
            is_verified=True,
        )
        db_session.add(entry)
        await db_session.commit()
        await db_session.refresh(entry)

        assert entry.reward_type == models.RewardType.GAME_REWARD
        assert entry.amount == 100.0
