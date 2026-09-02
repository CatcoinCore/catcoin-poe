"""Social normalization + fraud flag rules for profile updates."""

import pytest
from httpx import ASGITransport, AsyncClient

import models
from main import app
from services.fraud_detection import FraudDetectionService
from services.social_lock_service import normalize_social_value


@pytest.mark.parametrize(
    "raw,expected",
    [
        (None, None),
        ("", None),
        ("   ", None),
        ("  user  ", "user"),
        ("@User", "user"),
        ("@USER", "user"),
        ("MixedCase", "mixedcase"),
    ],
)
def test_normalize_social_value_handles_whitespace_at_case(raw, expected):
    assert normalize_social_value(raw) == expected


@pytest.mark.asyncio
async def test_profile_first_discord_none_to_handle_not_suspicious(db_session, test_user):
    from database import get_db
    import auth as auth_module
    from sqlalchemy.future import select

    test_user.discord_id = None
    test_user.discord_id_verified = False
    await db_session.commit()

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
            r = await client.put("/auth/users/me/profile", json={"discord_id": "firstuser"})
        assert r.status_code == 200
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)

    n = (
        await db_session.execute(
            select(models.SuspiciousActivity).where(
                models.SuspiciousActivity.user_id == test_user.id,
                models.SuspiciousActivity.activity_type == "SOCIAL_PROFILE_CHANGED",
            )
        )
    ).scalars().first()
    assert n is None


@pytest.mark.asyncio
async def test_profile_first_discord_at_prefix_not_suspicious(db_session, test_user):
    from database import get_db
    import auth as auth_module
    from sqlalchemy.future import select

    test_user.discord_id = None
    test_user.discord_id_verified = False
    await db_session.commit()

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
            r = await client.put("/auth/users/me/profile", json={"discord_id": "@FirstUser"})
        assert r.status_code == 200
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)

    n = (
        await db_session.execute(
            select(models.SuspiciousActivity).where(
                models.SuspiciousActivity.user_id == test_user.id,
                models.SuspiciousActivity.activity_type == "SOCIAL_PROFILE_CHANGED",
            )
        )
    ).scalars().first()
    assert n is None


@pytest.mark.asyncio
async def test_profile_canonical_only_change_not_suspicious(db_session, test_user):
    """@user vs user after normalization — no meaningful change."""
    from database import get_db
    import auth as auth_module

    test_user.discord_id = "sameuser"
    test_user.discord_id_verified = False
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
                json={"discord_id": "@sameuser"},
            )
        assert r.status_code == 200
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)

    from sqlalchemy.future import select

    n = (
        await db_session.execute(
            select(models.SuspiciousActivity).where(
                models.SuspiciousActivity.user_id == test_user.id,
                models.SuspiciousActivity.activity_type == "SOCIAL_PROFILE_CHANGED",
            )
        )
    ).scalars().first()
    assert n is None


@pytest.mark.asyncio
async def test_non_admin_cannot_ping_inactive(db_session, test_user):
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
            r = await client.post("/v1/admin/users/ping-inactive")
        assert r.status_code == 403
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)


@pytest.mark.asyncio
async def test_resolve_review_then_new_flag_reopens_account(
    db_session, test_user, admin_user
):
    await FraudDetectionService.log_suspicious_activity(
        db_session, test_user.id, "SOCIAL_PROFILE_CHANGED", "evidence-a"
    )
    await db_session.commit()
    await db_session.refresh(test_user)
    assert test_user.is_suspicious is True

    from sqlalchemy.future import select

    act = (
        await db_session.execute(
            select(models.SuspiciousActivity).where(
                models.SuspiciousActivity.evidence == "evidence-a"
            )
        )
    ).scalars().first()
    assert act is not None

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
            r = await client.post(f"/v1/admin/suspicious-activity/{act.id}/resolve")
        assert r.status_code == 200
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)

    await db_session.refresh(test_user)
    assert test_user.is_suspicious is False

    await FraudDetectionService.log_suspicious_activity(
        db_session, test_user.id, "SOCIAL_PROFILE_CHANGED", "evidence-b"
    )
    await db_session.commit()
    await db_session.refresh(test_user)
    assert test_user.is_suspicious is True
