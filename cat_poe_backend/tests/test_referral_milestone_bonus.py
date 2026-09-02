"""Referral milestone bonus evaluation and payout."""
import uuid
from datetime import datetime, timedelta

import pytest
from sqlalchemy import select, text

import models
from fastapi import HTTPException

from services.referral_bonus import (
    DEFAULT_BONUS_CATOSHI,
    REFERRAL_RECONCILIATION_ADVISORY_LOCK_HOLD_SQL,
    REFERRAL_RECONCILIATION_ADVISORY_LOCK_UNLOCK_SQL,
    REFERRAL_RECONCILIATION_LOCK_KEY1,
    REFERRAL_RECONCILIATION_LOCK_KEY2,
    award_referral_bonus,
    ensure_referral_row,
    evaluate_referral_bonus,
    get_referral_live_metrics,
    read_referral_live_metrics,
    recalculate_for_referee,
    refresh_referral_bonus_snapshot,
    run_referral_bonus_reconciliation,
)


@pytest.mark.asyncio
async def test_evaluate_sets_eligible_when_thresholds_met(
    db_session, test_admin_config, test_user_password_hash
):
    """Referee meets mining days, mining sum, and game sum → referrer gets eligible + rewarded."""
    uid = uuid.uuid4().hex[:8]
    referrer = models.User(
        username=f"ref_{uid}",
        email=f"ref_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"REF{uid}",
        balance=0.0,
        email_verified=True,
    )
    referee = models.User(
        username=f"fee_{uid}",
        email=f"fee_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"FEE{uid}",
        referred_by=referrer.referral_code.lower(),
        balance=0.0,
        email_verified=True,
    )
    db_session.add_all([referrer, referee])
    await db_session.flush()

    ref = models.Referral(
        referrer_user_id=referrer.id,
        referee_user_id=referee.id,
        referred_at=datetime.utcnow(),
    )
    db_session.add(ref)
    await db_session.commit()

    # 30 distinct mining days (BASE, completed, >0)
    base = datetime(2025, 1, 1, 12, 0, 0)
    for d in range(30):
        day = base + timedelta(days=d)
        s = models.MiningSession(
            user_id=referee.id,
            session_type=models.SessionType.BASE,
            start_time=day,
            end_time=day + timedelta(hours=1),
            status=models.MiningStatus.COMPLETED,
            total_earned=1000.0,
            completed_at=day + timedelta(hours=1),
            reward_y=1,
            reward_t=1,
        )
        db_session.add(s)
    await db_session.commit()

    # Mining reward sum (MINING_BASE ledger)
    db_session.add(
        models.EarningsLedger(
            user_id=referee.id,
            amount=300_000_000.0,
            reward_type=models.RewardType.MINING_BASE,
            is_verified=True,
        )
    )
    # Game rewards
    gs = models.GameSession(
        user_id=referee.id,
        session_token=str(uuid.uuid4()),
        start_time=datetime.utcnow(),
        end_time=datetime.utcnow(),
        validated=True,
    )
    db_session.add(gs)
    await db_session.flush()
    db_session.add(
        models.GameReward(
            user_id=referee.id,
            session_id=gs.id,
            reward_catoshi=10_000,
        )
    )
    await db_session.commit()

    await evaluate_referral_bonus(db_session, ref.id, allow_award=True)
    await db_session.commit()

    r2 = await db_session.get(models.Referral, ref.id)
    assert r2.bonus_status == "rewarded"
    assert r2.bonus_awarded_at is not None
    assert int(r2.bonus_amount_catoshi) == DEFAULT_BONUS_CATOSHI

    led = await db_session.execute(
        select(models.EarningsLedger).where(
            models.EarningsLedger.user_id == referrer.id,
            models.EarningsLedger.reward_type == models.RewardType.REFERRAL_BONUS,
        )
    )
    rows = led.scalars().all()
    assert len(rows) == 1
    assert rows[0].referral_id == ref.id
    assert abs(rows[0].amount - float(DEFAULT_BONUS_CATOSHI)) < 1


@pytest.mark.asyncio
async def test_recalculate_for_referee_no_op_without_row(db_session, test_admin_config):
    await recalculate_for_referee(db_session, uuid.uuid4())


@pytest.mark.asyncio
async def test_pending_zero_progress(db_session, test_user_password_hash):
    uid = uuid.uuid4().hex[:8]
    referrer = models.User(
        username=f"a_{uid}",
        email=f"a_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"A{uid}",
        balance=0.0,
        email_verified=True,
    )
    referee = models.User(
        username=f"b_{uid}",
        email=f"b_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"B{uid}",
        referred_by=referrer.referral_code.lower(),
        balance=0.0,
        email_verified=True,
    )
    db_session.add_all([referrer, referee])
    await db_session.flush()
    ref = models.Referral(
        referrer_user_id=referrer.id,
        referee_user_id=referee.id,
        referred_at=datetime.utcnow(),
    )
    db_session.add(ref)
    await db_session.commit()

    await evaluate_referral_bonus(db_session, ref.id, allow_award=True)
    await db_session.commit()
    r2 = await db_session.get(models.Referral, ref.id)
    assert r2.bonus_status == "pending"
    assert r2.conditions_met_count == 0


@pytest.mark.asyncio
async def test_mining_threshold_excludes_non_mining_ledger(
    db_session, test_user_password_hash
):
    uid = uuid.uuid4().hex[:8]
    u = models.User(
        username=f"u_{uid}",
        email=f"u_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"U{uid}",
        balance=0.0,
        email_verified=True,
    )
    db_session.add(u)
    await db_session.flush()
    db_session.add(
        models.EarningsLedger(
            user_id=u.id,
            amount=500_000_000.0,
            reward_type=models.RewardType.GAME_REWARD,
        )
    )
    await db_session.commit()
    m = (await get_referral_live_metrics(db_session, u.id))[1]
    assert m == 0


@pytest.mark.asyncio
async def test_game_threshold_only_game_rewards_table(
    db_session, test_user_password_hash
):
    uid = uuid.uuid4().hex[:8]
    u = models.User(
        username=f"g_{uid}",
        email=f"g_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"G{uid}",
        balance=0.0,
        email_verified=True,
    )
    db_session.add(u)
    await db_session.flush()
    db_session.add(
        models.EarningsLedger(
            user_id=u.id,
            amount=99_999_999.0,
            reward_type=models.RewardType.MINING_BASE,
        )
    )
    await db_session.commit()
    g = (await get_referral_live_metrics(db_session, u.id))[2]
    assert g == 0


@pytest.mark.asyncio
async def test_distinct_mined_days_same_calendar_day_counts_once(
    db_session, test_user_password_hash
):
    uid = uuid.uuid4().hex[:8]
    u = models.User(
        username=f"d_{uid}",
        email=f"d_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"D{uid}",
        balance=0.0,
        email_verified=True,
    )
    db_session.add(u)
    await db_session.flush()
    day = datetime(2025, 3, 1, 10, 0, 0)
    for _ in range(3):
        db_session.add(
            models.MiningSession(
                user_id=u.id,
                session_type=models.SessionType.BASE,
                start_time=day,
                end_time=day + timedelta(hours=1),
                status=models.MiningStatus.COMPLETED,
                total_earned=100.0,
                completed_at=day + timedelta(hours=1),
                reward_y=1,
                reward_t=1,
            )
        )
    await db_session.commit()
    md = (await get_referral_live_metrics(db_session, u.id))[0]
    assert md == 1


@pytest.mark.asyncio
async def test_second_award_raises(db_session, test_user_password_hash, test_admin_config):
    uid = uuid.uuid4().hex[:8]
    referrer = models.User(
        username=f"r2_{uid}",
        email=f"r2_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"R2{uid}",
        balance=0.0,
        email_verified=True,
    )
    referee = models.User(
        username=f"f2_{uid}",
        email=f"f2_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"F2{uid}",
        referred_by=referrer.referral_code.lower(),
        balance=0.0,
        email_verified=True,
    )
    db_session.add_all([referrer, referee])
    await db_session.flush()
    ref = models.Referral(
        referrer_user_id=referrer.id,
        referee_user_id=referee.id,
        referred_at=datetime.utcnow(),
    )
    db_session.add(ref)
    await db_session.commit()

    base = datetime(2025, 1, 1, 12, 0, 0)
    for d in range(30):
        day = base + timedelta(days=d)
        db_session.add(
            models.MiningSession(
                user_id=referee.id,
                session_type=models.SessionType.BASE,
                start_time=day,
                end_time=day + timedelta(hours=1),
                status=models.MiningStatus.COMPLETED,
                total_earned=1000.0,
                completed_at=day + timedelta(hours=1),
                reward_y=1,
                reward_t=1,
            )
        )
    db_session.add(
        models.EarningsLedger(
            user_id=referee.id,
            amount=300_000_000.0,
            reward_type=models.RewardType.MINING_BASE,
        )
    )
    gs = models.GameSession(
        user_id=referee.id,
        session_token=str(uuid.uuid4()),
        start_time=datetime.utcnow(),
        end_time=datetime.utcnow(),
        validated=True,
    )
    db_session.add(gs)
    await db_session.flush()
    db_session.add(
        models.GameReward(
            user_id=referee.id,
            session_id=gs.id,
            reward_catoshi=10_000,
        )
    )
    await db_session.commit()

    await evaluate_referral_bonus(db_session, ref.id, allow_award=True)
    await db_session.commit()

    with pytest.raises(HTTPException) as ei:
        await award_referral_bonus(db_session, ref.id, commit=False)
    assert ei.value.status_code == 400


@pytest.mark.asyncio
async def test_ensure_referral_row_self_returns_none(
    db_session, test_user_password_hash
):
    uid = uuid.uuid4().hex[:8]
    u = models.User(
        username=f"s_{uid}",
        email=f"s_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"S{uid}",
        balance=0.0,
        email_verified=True,
    )
    db_session.add(u)
    await db_session.commit()
    row = await ensure_referral_row(db_session, u, u)
    assert row is None


@pytest.mark.asyncio
async def test_under_review_skips_auto_award_until_resume(
    db_session, test_user_password_hash, test_admin_config
):
    uid = uuid.uuid4().hex[:8]
    referrer = models.User(
        username=f"ur_{uid}",
        email=f"ur_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"UR{uid}",
        balance=0.0,
        email_verified=True,
    )
    referee = models.User(
        username=f"uf_{uid}",
        email=f"uf_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"UF{uid}",
        referred_by=referrer.referral_code.lower(),
        balance=0.0,
        email_verified=True,
    )
    db_session.add_all([referrer, referee])
    await db_session.flush()
    ref = models.Referral(
        referrer_user_id=referrer.id,
        referee_user_id=referee.id,
        referred_at=datetime.utcnow(),
        bonus_status="under_review",
    )
    db_session.add(ref)
    await db_session.commit()

    base = datetime(2025, 1, 1, 12, 0, 0)
    for d in range(30):
        day = base + timedelta(days=d)
        db_session.add(
            models.MiningSession(
                user_id=referee.id,
                session_type=models.SessionType.BASE,
                start_time=day,
                end_time=day + timedelta(hours=1),
                status=models.MiningStatus.COMPLETED,
                total_earned=1000.0,
                completed_at=day + timedelta(hours=1),
                reward_y=1,
                reward_t=1,
            )
        )
    db_session.add(
        models.EarningsLedger(
            user_id=referee.id,
            amount=300_000_000.0,
            reward_type=models.RewardType.MINING_BASE,
        )
    )
    gs = models.GameSession(
        user_id=referee.id,
        session_token=str(uuid.uuid4()),
        start_time=datetime.utcnow(),
        end_time=datetime.utcnow(),
        validated=True,
    )
    db_session.add(gs)
    await db_session.flush()
    db_session.add(
        models.GameReward(
            user_id=referee.id,
            session_id=gs.id,
            reward_catoshi=10_000,
        )
    )
    await db_session.commit()

    await evaluate_referral_bonus(db_session, ref.id, allow_award=True)
    await db_session.commit()
    r2 = await db_session.get(models.Referral, ref.id)
    assert r2.bonus_status == "under_review"
    assert r2.bonus_awarded_at is None


@pytest.mark.asyncio
async def test_refresh_snapshot_only_does_not_award_when_eligible(
    db_session, test_user_password_hash, test_admin_config
):
    """GET-style path: refresh snapshot updates status but never credits or sets bonus_awarded_at."""
    uid = uuid.uuid4().hex[:8]
    referrer = models.User(
        username=f"rx_{uid}",
        email=f"rx_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"RX{uid}",
        balance=0.0,
        email_verified=True,
    )
    referee = models.User(
        username=f"fx_{uid}",
        email=f"fx_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"FX{uid}",
        referred_by=referrer.referral_code.lower(),
        balance=0.0,
        email_verified=True,
    )
    db_session.add_all([referrer, referee])
    await db_session.flush()
    ref = models.Referral(
        referrer_user_id=referrer.id,
        referee_user_id=referee.id,
        referred_at=datetime.utcnow(),
    )
    db_session.add(ref)
    await db_session.commit()

    base = datetime(2025, 1, 1, 12, 0, 0)
    for d in range(30):
        day = base + timedelta(days=d)
        db_session.add(
            models.MiningSession(
                user_id=referee.id,
                session_type=models.SessionType.BASE,
                start_time=day,
                end_time=day + timedelta(hours=1),
                status=models.MiningStatus.COMPLETED,
                total_earned=1000.0,
                completed_at=day + timedelta(hours=1),
                reward_y=1,
                reward_t=1,
            )
        )
    db_session.add(
        models.EarningsLedger(
            user_id=referee.id,
            amount=300_000_000.0,
            reward_type=models.RewardType.MINING_BASE,
        )
    )
    gs = models.GameSession(
        user_id=referee.id,
        session_token=str(uuid.uuid4()),
        start_time=datetime.utcnow(),
        end_time=datetime.utcnow(),
        validated=True,
    )
    db_session.add(gs)
    await db_session.flush()
    db_session.add(
        models.GameReward(
            user_id=referee.id,
            session_id=gs.id,
            reward_catoshi=10_000,
        )
    )
    await db_session.commit()

    live_before = await read_referral_live_metrics(db_session, referee.id)
    assert live_before.eligible is True

    await refresh_referral_bonus_snapshot(db_session, ref.id, force_recalc=True)
    await db_session.commit()

    r2 = await db_session.get(models.Referral, ref.id)
    assert (r2.bonus_status or "").lower() == "eligible"
    assert r2.bonus_awarded_at is None

    led = await db_session.execute(
        select(models.EarningsLedger).where(
            models.EarningsLedger.user_id == referrer.id,
            models.EarningsLedger.reward_type == models.RewardType.REFERRAL_BONUS,
        )
    )
    assert len(led.scalars().all()) == 0

    await evaluate_referral_bonus(db_session, ref.id, allow_award=True)
    await db_session.commit()
    r3 = await db_session.get(models.Referral, ref.id)
    assert r3.bonus_awarded_at is not None
    led2 = await db_session.execute(
        select(models.EarningsLedger).where(
            models.EarningsLedger.user_id == referrer.id,
            models.EarningsLedger.reward_type == models.RewardType.REFERRAL_BONUS,
        )
    )
    assert len(led2.scalars().all()) == 1


@pytest.mark.asyncio
async def test_reconciliation_skips_when_advisory_lock_held(
    db_session, dual_db_sessions, test_user_password_hash, test_admin_config
):
    """Second runner must not execute inner scan when lock is held by another session."""
    s_hold, s_run = dual_db_sessions

    uid = uuid.uuid4().hex[:8]
    referrer = models.User(
        username=f"lk_{uid}",
        email=f"lk_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"LK{uid}",
        balance=0.0,
        email_verified=True,
    )
    referee = models.User(
        username=f"fk_{uid}",
        email=f"fk_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"FK{uid}",
        referred_by=referrer.referral_code.lower(),
        balance=0.0,
        email_verified=True,
    )
    db_session.add_all([referrer, referee])
    await db_session.flush()
    ref = models.Referral(
        referrer_user_id=referrer.id,
        referee_user_id=referee.id,
        referred_at=datetime.utcnow(),
    )
    db_session.add(ref)
    await db_session.commit()

    await s_hold.execute(
        text(REFERRAL_RECONCILIATION_ADVISORY_LOCK_HOLD_SQL),
        {"k1": REFERRAL_RECONCILIATION_LOCK_KEY1, "k2": REFERRAL_RECONCILIATION_LOCK_KEY2},
    )
    # Keep the session transaction open until after the competing call — same keys/SQL
    # as production (explicit INT) so we contend for the same lock family.

    n = await run_referral_bonus_reconciliation(s_run)
    assert n == 0

    await s_hold.execute(
        text(REFERRAL_RECONCILIATION_ADVISORY_LOCK_UNLOCK_SQL),
        {"k1": REFERRAL_RECONCILIATION_LOCK_KEY1, "k2": REFERRAL_RECONCILIATION_LOCK_KEY2},
    )
    await s_hold.commit()


@pytest.mark.asyncio
async def test_reconciliation_awards_eligible_when_lock_acquired(
    db_session, test_user_password_hash, test_admin_config
):
    uid = uuid.uuid4().hex[:8]
    referrer = models.User(
        username=f"rw_{uid}",
        email=f"rw_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"RW{uid}",
        balance=0.0,
        email_verified=True,
    )
    referee = models.User(
        username=f"fw_{uid}",
        email=f"fw_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"FW{uid}",
        referred_by=referrer.referral_code.lower(),
        balance=0.0,
        email_verified=True,
    )
    db_session.add_all([referrer, referee])
    await db_session.flush()
    ref = models.Referral(
        referrer_user_id=referrer.id,
        referee_user_id=referee.id,
        referred_at=datetime.utcnow(),
    )
    db_session.add(ref)
    await db_session.commit()

    base = datetime(2025, 1, 1, 12, 0, 0)
    for d in range(30):
        day = base + timedelta(days=d)
        db_session.add(
            models.MiningSession(
                user_id=referee.id,
                session_type=models.SessionType.BASE,
                start_time=day,
                end_time=day + timedelta(hours=1),
                status=models.MiningStatus.COMPLETED,
                total_earned=1000.0,
                completed_at=day + timedelta(hours=1),
                reward_y=1,
                reward_t=1,
            )
        )
    db_session.add(
        models.EarningsLedger(
            user_id=referee.id,
            amount=300_000_000.0,
            reward_type=models.RewardType.MINING_BASE,
        )
    )
    gs = models.GameSession(
        user_id=referee.id,
        session_token=str(uuid.uuid4()),
        start_time=datetime.utcnow(),
        end_time=datetime.utcnow(),
        validated=True,
    )
    db_session.add(gs)
    await db_session.flush()
    db_session.add(
        models.GameReward(
            user_id=referee.id,
            session_id=gs.id,
            reward_catoshi=10_000,
        )
    )
    await db_session.commit()

    processed = await run_referral_bonus_reconciliation(db_session)
    assert processed >= 1

    r2 = await db_session.get(models.Referral, ref.id)
    assert r2.bonus_status == "rewarded"
    assert r2.bonus_awarded_at is not None
