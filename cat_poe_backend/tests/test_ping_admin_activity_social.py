"""Ping flows, admin activity filters, social fraud noise, suspicious resolution, mining reset."""

import uuid
from datetime import datetime, timedelta

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.future import select

import models
from main import app
from services.fraud_detection import FraudDetectionService
from services.user_activity import user_is_active_for_admin


@pytest.mark.asyncio
async def test_referral_bulk_ping_only_inactive_referrals(
    db_session, test_user, test_user_password_hash
):
    rid = uuid.uuid4().hex[:8]
    # Inactive: older than engagement window (User model defaults last_active_at on insert)
    ref_inactive = models.User(
        username=f"refp_{rid}",
        email=f"refp_{rid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"RRP{rid}",
        referred_by=test_user.referral_code,
        balance=0.0,
        email_verified=True,
        last_active_at=datetime.utcnow() - timedelta(hours=25),
    )
    # Active in app: recent last_active_at — must not be pinged
    ref_active = models.User(
        username=f"refa_{rid}",
        email=f"refa_{rid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"RRA{rid}",
        referred_by=test_user.referral_code,
        balance=0.0,
        email_verified=True,
        last_active_at=datetime.utcnow(),
    )
    db_session.add(ref_inactive)
    db_session.add(ref_active)
    await db_session.commit()

    from database import get_db
    import auth as auth_module

    async def _db():
        yield db_session

    async def _user():
        return test_user

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[auth_module.get_current_user] = _user
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.post("/referrals/ping-all")
            assert r.status_code == 200
            body = r.json()
            assert body["total_targets"] == 1
            assert body["pinged"] == 1
            assert body["skipped"] == 0

            r2 = await client.post("/referrals/ping-all")
            assert r2.status_code == 200
            body2 = r2.json()
            assert body2["total_targets"] == 1
            assert body2["pinged"] == 0
            assert body2["skipped"] == 1
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)


@pytest.mark.asyncio
async def test_admin_users_activity_summary_and_filter(
    db_session, test_user, admin_user, test_user_password_hash
):
    now = datetime.utcnow()
    test_user.last_active_at = now
    stale = models.User(
        username="stale_u",
        email="stale_u@test.com",
        hashed_password=test_user_password_hash,
        referral_code="STALE01",
        balance=0.0,
        email_verified=True,
        last_active_at=now - timedelta(days=10),
    )
    db_session.add(stale)
    await db_session.commit()

    from database import get_db
    import auth as auth_module

    async def _db():
        yield db_session

    async def _admin():
        return admin_user

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[auth_module.get_current_user] = _admin
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.get("/v1/admin/users?limit=50&skip=0&activity_status=all")
            assert r.status_code == 200
            data = r.json()
            s = data["activity_summary"]
            assert s["total_users"] >= 2
            assert s["active_users"] >= 1
            assert s["inactive_users"] >= 1

            r2 = await client.get("/v1/admin/users?limit=50&activity_status=inactive")
            assert r2.status_code == 200
            usernames = {u["username"] for u in r2.json()["users"]}
            assert "stale_u" in usernames
            assert test_user.username not in usernames
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)


@pytest.mark.asyncio
async def test_profile_first_discord_set_not_suspicious(db_session, test_user):
    from database import get_db
    import auth as auth_module

    async def _db():
        yield db_session

    async def _user():
        return test_user

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[auth_module.get_current_user] = _user
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.put(
                "/auth/users/me/profile",
                json={"discord_id": "first_handle"},
            )
        assert r.status_code == 200
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)

    r = await db_session.execute(
        select(models.SuspiciousActivity).where(
            models.SuspiciousActivity.user_id == test_user.id,
            models.SuspiciousActivity.activity_type == "SOCIAL_PROFILE_CHANGED",
        )
    )
    assert r.scalars().first() is None


@pytest.mark.asyncio
async def test_profile_social_change_a_to_b_is_suspicious(db_session, test_user):
    from database import get_db
    import auth as auth_module

    test_user.discord_id = "aaa"
    test_user.discord_id_verified = False
    db_session.add(test_user)
    await db_session.commit()
    await db_session.refresh(test_user)

    async def _db():
        yield db_session

    async def _user():
        return test_user

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[auth_module.get_current_user] = _user
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.put(
                "/auth/users/me/profile",
                json={"discord_id": "bbb"},
            )
        assert r.status_code == 200
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)

    r = await db_session.execute(
        select(models.SuspiciousActivity).where(
            models.SuspiciousActivity.user_id == test_user.id,
            models.SuspiciousActivity.activity_type == "SOCIAL_PROFILE_CHANGED",
            models.SuspiciousActivity.is_resolved == False,  # noqa: E712
        )
    )
    assert r.scalars().first() is not None


@pytest.mark.asyncio
async def test_resolve_then_repeat_social_change_flags_again(db_session, test_user):
    await FraudDetectionService.log_suspicious_activity(
        db_session,
        test_user.id,
        "SOCIAL_PROFILE_CHANGED",
        "unit evidence 1",
    )
    await db_session.commit()
    await db_session.refresh(test_user)
    act = (
        await db_session.execute(
            select(models.SuspiciousActivity).where(
                models.SuspiciousActivity.user_id == test_user.id,
                models.SuspiciousActivity.evidence == "unit evidence 1",
            )
        )
    ).scalars().first()
    assert act is not None
    act.is_resolved = True
    await db_session.commit()

    await FraudDetectionService.log_suspicious_activity(
        db_session,
        test_user.id,
        "SOCIAL_PROFILE_CHANGED",
        "unit evidence 1",
    )
    await db_session.commit()
    rows = (
        await db_session.execute(
            select(models.SuspiciousActivity).where(
                models.SuspiciousActivity.user_id == test_user.id,
                models.SuspiciousActivity.evidence == "unit evidence 1",
            )
        )
    ).scalars().all()
    assert len(rows) == 2


@pytest.mark.asyncio
async def test_unmark_suspicious_does_not_resolve_open_logs(db_session, test_user, admin_user):
    await FraudDetectionService.log_suspicious_activity(
        db_session,
        test_user.id,
        "SOCIAL_PROFILE_CHANGED",
        "open item",
    )
    await db_session.commit()

    from database import get_db
    import auth as auth_module

    async def _db():
        yield db_session

    async def _admin():
        return admin_user

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[auth_module.get_current_user] = _admin
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.post(f"/v1/admin/users/{test_user.id}/unmark-suspicious")
        assert r.status_code == 200
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)

    row = (
        await db_session.execute(
            select(models.SuspiciousActivity).where(
                models.SuspiciousActivity.evidence == "open item"
            )
        )
    ).scalars().first()
    assert row.is_resolved is False


@pytest.mark.asyncio
async def test_reset_mining_clears_game_boost_inventory(
    db_session, test_user, test_admin_config, admin_user
):
    now = datetime.utcnow()
    base = models.MiningSession(
        user_id=test_user.id,
        session_type=models.SessionType.BASE,
        start_time=now,
        end_time=now + timedelta(hours=4),
        status=models.MiningStatus.ACTIVE,
        reward_y=10,
        reward_t=1,
    )
    boost = models.UserGameBoost(
        user_id=test_user.id,
        percentage=10.0,
        duration_minutes=60,
        is_used=True,
    )
    db_session.add_all([base, boost])
    await db_session.commit()
    await db_session.refresh(boost)
    gb = models.MiningSession(
        user_id=test_user.id,
        session_type=models.SessionType.GAME_BOOST,
        start_time=now,
        end_time=now + timedelta(hours=1),
        status=models.MiningStatus.ACTIVE,
        reward_y=5,
        reward_t=1,
    )
    db_session.add(gb)
    await db_session.commit()
    await db_session.refresh(gb)
    boost.session_id = gb.id
    db_session.add(boost)
    gc = models.GameCooldown(
        user_id=test_user.id,
        game_type="SUDOKU",
        play_count=3,
        cooldown_until=now + timedelta(hours=1),
    )
    db_session.add(gc)
    ledger = models.EarningsLedger(
        user_id=test_user.id,
        amount=1.0,
        reward_type=models.RewardType.MINING_BASE,
        description="reset test ledger",
    )
    db_session.add(ledger)
    await db_session.flush()
    mapping = models.LedgerSessionMapping(
        ledger_entry_id=ledger.id,
        session_id=base.id,
        session_contribution=1.0,
    )
    db_session.add(mapping)
    await db_session.commit()

    from database import get_db
    import auth as auth_module

    async def _db():
        yield db_session

    async def _admin():
        return admin_user

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[auth_module.get_current_user] = _admin
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.post(f"/v1/admin/users/{test_user.id}/reset-mining")
        assert r.status_code == 200
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)

    active = (
        await db_session.execute(
            select(models.MiningSession).where(
                models.MiningSession.user_id == test_user.id,
                models.MiningSession.status == models.MiningStatus.ACTIVE,
            )
        )
    ).scalars().all()
    assert active == []

    await db_session.refresh(boost)
    assert boost.is_used is False
    assert boost.session_id is None

    gc_row = (
        await db_session.execute(
            select(models.GameCooldown).where(models.GameCooldown.user_id == test_user.id)
        )
    ).scalars().first()
    assert gc_row is None

    map_count = (
        await db_session.execute(
            select(models.LedgerSessionMapping).where(
                models.LedgerSessionMapping.ledger_entry_id == ledger.id
            )
        )
    ).scalars().all()
    assert map_count == []


@pytest.mark.asyncio
async def test_reset_mining_preserves_historical_consumed_boosts(
    db_session, test_user, test_admin_config, admin_user
):
    """
    Regression: ``/admin/users/{id}/reset-mining`` must reset only inventory boosts
    that are tied to an *active* mining session being torn down. Previously consumed
    boosts (linked to completed sessions) must stay ``is_used=True`` so they cannot
    be re-activated and re-paid.
    """
    now = datetime.utcnow()

    completed_gb = models.MiningSession(
        user_id=test_user.id,
        session_type=models.SessionType.GAME_BOOST,
        start_time=now - timedelta(hours=3),
        end_time=now - timedelta(hours=2),
        status=models.MiningStatus.COMPLETED,
        completed_at=now - timedelta(hours=2),
        reward_y=5,
        reward_t=1,
        total_earned=42,
    )
    db_session.add(completed_gb)
    await db_session.commit()
    await db_session.refresh(completed_gb)

    historical_boost = models.UserGameBoost(
        user_id=test_user.id,
        percentage=10.0,
        duration_minutes=60,
        is_used=True,
        session_id=completed_gb.id,
    )
    db_session.add(historical_boost)

    base = models.MiningSession(
        user_id=test_user.id,
        session_type=models.SessionType.BASE,
        start_time=now,
        end_time=now + timedelta(hours=4),
        status=models.MiningStatus.ACTIVE,
        reward_y=10,
        reward_t=1,
    )
    active_gb = models.MiningSession(
        user_id=test_user.id,
        session_type=models.SessionType.GAME_BOOST,
        start_time=now,
        end_time=now + timedelta(hours=1),
        status=models.MiningStatus.ACTIVE,
        reward_y=5,
        reward_t=1,
    )
    db_session.add_all([base, active_gb])
    await db_session.commit()
    await db_session.refresh(active_gb)

    active_boost = models.UserGameBoost(
        user_id=test_user.id,
        percentage=15.0,
        duration_minutes=120,
        is_used=True,
        session_id=active_gb.id,
    )
    db_session.add(active_boost)
    await db_session.commit()
    await db_session.refresh(historical_boost)
    await db_session.refresh(active_boost)

    historical_id = historical_boost.id
    active_id = active_boost.id

    from database import get_db
    import auth as auth_module

    async def _db():
        yield db_session

    async def _admin():
        return admin_user

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[auth_module.get_current_user] = _admin
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.post(f"/v1/admin/users/{test_user.id}/reset-mining")
        assert r.status_code == 200
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)

    historical_after = (
        await db_session.execute(
            select(models.UserGameBoost).where(models.UserGameBoost.id == historical_id)
        )
    ).scalars().first()
    assert historical_after is not None
    assert historical_after.is_used is True, (
        "consumed boosts must not be returned to inventory by reset-mining"
    )
    assert historical_after.session_id == completed_gb.id

    active_after = (
        await db_session.execute(
            select(models.UserGameBoost).where(models.UserGameBoost.id == active_id)
        )
    ).scalars().first()
    assert active_after is not None
    assert active_after.is_used is False
    assert active_after.session_id is None

    completed_still_there = (
        await db_session.execute(
            select(models.MiningSession).where(models.MiningSession.id == completed_gb.id)
        )
    ).scalars().first()
    assert completed_still_there is not None

    active_after_sessions = (
        await db_session.execute(
            select(models.MiningSession).where(
                models.MiningSession.user_id == test_user.id,
                models.MiningSession.status == models.MiningStatus.ACTIVE,
            )
        )
    ).scalars().all()
    assert active_after_sessions == []


@pytest.mark.asyncio
async def test_ping_inactive_skips_admin_accounts(db_session, admin_user):
    """Inactive-user ping must not target admin accounts."""
    admin_user.last_active_at = datetime.utcnow() - timedelta(days=30)
    await db_session.commit()

    from database import get_db
    import auth as auth_module

    async def _db():
        yield db_session

    async def _admin():
        return admin_user

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[auth_module.get_current_user] = _admin
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.post("/v1/admin/users/ping-inactive")
        assert r.status_code == 200
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)

    n = (
        await db_session.execute(
            select(models.UserPingNotification).where(
                models.UserPingNotification.recipient_user_id == admin_user.id
            )
        )
    ).scalars().first()
    assert n is None


@pytest.mark.asyncio
async def test_user_is_active_for_admin_window(db_session, test_user):
    test_user.last_active_at = datetime.utcnow()
    assert user_is_active_for_admin(test_user) is True
    test_user.last_active_at = datetime.utcnow() - timedelta(hours=25)
    assert user_is_active_for_admin(test_user) is False


@pytest.mark.asyncio
async def test_admin_put_user_verifies_email_and_clears_code(
    db_session, admin_user, test_user_password_hash
):
    rid = uuid.uuid4().hex[:8]
    u = models.User(
        username=f"unver_{rid}",
        email=f"unver_{rid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"UNV{rid}",
        balance=0.0,
        email_verified=False,
        verification_code="123456",
        verification_code_expires=datetime.utcnow() + timedelta(hours=1),
    )
    db_session.add(u)
    await db_session.commit()
    await db_session.refresh(u)

    from database import get_db
    import auth as auth_module

    async def _db():
        yield db_session

    async def _admin():
        return admin_user

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[auth_module.get_current_user] = _admin
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.put(
                f"/v1/admin/users/{u.id}",
                json={"email_verified": True},
            )
        assert r.status_code == 200
        body = r.json()
        assert body["email_verified"] is True
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)

    await db_session.refresh(u)
    assert u.email_verified is True
    assert u.verification_code is None
    assert u.verification_code_expires is None

