"""Referral boost closes when the referred user has no active BASE mining session."""
import uuid
from datetime import datetime, timedelta

import pytest

import models
from services.session_manager import SessionManager


@pytest.mark.asyncio
async def test_close_referral_boost_when_referral_not_mining(
    db_session, test_user, test_admin_config
):
    now = datetime.utcnow()
    rid = uuid.uuid4().hex[:8]
    referral = models.User(
        username=f"ref_{rid}",
        email=f"ref_{rid}@t.com",
        hashed_password="x",
        referral_code=f"RREF{rid}",
        referred_by=test_user.referral_code,
        balance=0.0,
    )
    db_session.add(referral)
    await db_session.commit()
    await db_session.refresh(referral)

    base = models.MiningSession(
        user_id=test_user.id,
        session_type=models.SessionType.BASE,
        start_time=now,
        end_time=now + timedelta(hours=8),
        status=models.MiningStatus.ACTIVE,
        reward_y=100,
        reward_t=1,
    )
    ref_boost = models.MiningSession(
        user_id=test_user.id,
        session_type=models.SessionType.REFERRAL_BOOST,
        mining_for=referral.id,
        start_time=now,
        end_time=now + timedelta(hours=8),
        status=models.MiningStatus.ACTIVE,
        reward_y=50,
        reward_t=1,
    )
    db_session.add_all([base, ref_boost])
    await db_session.commit()
    await db_session.refresh(ref_boost)

    n = await SessionManager.close_referral_boosts_for_inactive_referrals(
        test_user.id, db_session
    )
    assert n == 1

    await db_session.refresh(ref_boost)
    assert ref_boost.end_time <= datetime.utcnow()

    completed = await SessionManager.complete_expired_sessions(test_user.id, db_session)
    assert len(completed) == 1
    assert completed[0].session_type == models.SessionType.REFERRAL_BOOST
    assert completed[0].status == models.MiningStatus.COMPLETED


@pytest.mark.asyncio
async def test_referral_boost_kept_when_referral_has_active_base(
    db_session, test_user, test_admin_config
):
    now = datetime.utcnow()
    rid2 = uuid.uuid4().hex[:8]
    referral = models.User(
        username=f"ref2_{rid2}",
        email=f"ref2_{rid2}@t.com",
        hashed_password="x",
        referral_code=f"RREF2{rid2}",
        referred_by=test_user.referral_code,
        balance=0.0,
    )
    db_session.add(referral)
    await db_session.commit()
    await db_session.refresh(referral)

    end = now + timedelta(hours=8)
    referral_base = models.MiningSession(
        user_id=referral.id,
        session_type=models.SessionType.BASE,
        start_time=now,
        end_time=end,
        status=models.MiningStatus.ACTIVE,
        reward_y=10,
        reward_t=1,
    )
    ref_boost = models.MiningSession(
        user_id=test_user.id,
        session_type=models.SessionType.REFERRAL_BOOST,
        mining_for=referral.id,
        start_time=now,
        end_time=end,
        status=models.MiningStatus.ACTIVE,
        reward_y=50,
        reward_t=1,
    )
    db_session.add_all([referral_base, ref_boost])
    await db_session.commit()

    n = await SessionManager.close_referral_boosts_for_inactive_referrals(
        test_user.id, db_session
    )
    assert n == 0

    await db_session.refresh(ref_boost)
    assert ref_boost.end_time == end
    assert ref_boost.status == models.MiningStatus.ACTIVE


@pytest.mark.asyncio
async def test_new_referral_boost_session_after_referral_stops_mining_same_miner_base(
    db_session, test_user, test_admin_config
):
    """Miner keeps same BASE: boost → referral ends their base session → new boost after they mine again."""
    test_admin_config.use_manual_cat_price = True
    test_admin_config.manual_cat_price_usdt = 1_000_000  # 1 USDT
    await db_session.commit()

    now = datetime.utcnow()
    rid = uuid.uuid4().hex[:8]
    referral = models.User(
        username=f"ref3_{rid}",
        email=f"ref3_{rid}@t.com",
        hashed_password="x",
        referral_code=f"RREF3{rid}",
        referred_by=test_user.referral_code,
        balance=0.0,
    )
    db_session.add(referral)
    await db_session.commit()
    await db_session.refresh(referral)

    miner_base = models.MiningSession(
        user_id=test_user.id,
        session_type=models.SessionType.BASE,
        start_time=now,
        end_time=now + timedelta(hours=24),
        status=models.MiningStatus.ACTIVE,
        reward_y=100,
        reward_t=1,
    )
    referral_base = models.MiningSession(
        user_id=referral.id,
        session_type=models.SessionType.BASE,
        start_time=now,
        end_time=now + timedelta(hours=12),
        status=models.MiningStatus.ACTIVE,
        reward_y=10,
        reward_t=1,
    )
    db_session.add_all([miner_base, referral_base])
    await db_session.commit()

    first = await SessionManager.create_referral_boost_session(
        str(test_user.id),
        test_user.referral_code,
        str(referral.id),
        db_session,
    )
    assert first.status == models.MiningStatus.ACTIVE

    # Referral's mining session ends (they stopped / completed)
    referral_base.end_time = now - timedelta(minutes=1)
    await db_session.commit()
    await SessionManager.cleanup_user_mining_sessions(referral.id, db_session)

    await SessionManager.cleanup_user_mining_sessions(test_user.id, db_session)

    await db_session.refresh(first)
    assert first.status == models.MiningStatus.COMPLETED

    # Referral starts mining again
    referral_base2 = models.MiningSession(
        user_id=referral.id,
        session_type=models.SessionType.BASE,
        start_time=now,
        end_time=now + timedelta(hours=12),
        status=models.MiningStatus.ACTIVE,
        reward_y=10,
        reward_t=1,
    )
    db_session.add(referral_base2)
    await db_session.commit()

    second = await SessionManager.create_referral_boost_session(
        str(test_user.id),
        test_user.referral_code,
        str(referral.id),
        db_session,
    )
    assert second.id != first.id
    assert second.status == models.MiningStatus.ACTIVE
    assert second.session_type == models.SessionType.REFERRAL_BOOST
