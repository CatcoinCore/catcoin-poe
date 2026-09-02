import uuid

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.future import select

import models
from main import app
from services.social_lock_service import (
    apply_social_verified_and_locked,
    revoke_platform_mission_rewards,
)
from services.session_manager import EarningsManager


@pytest.mark.asyncio
async def test_apply_social_verified_and_locked_sets_id_and_lock(db_session, test_user):
    apply_social_verified_and_locked(test_user, "discord", "proof_handle")
    assert test_user.discord_id == "proof_handle"
    assert test_user.discord_id_verified is True
    assert test_user.discord_id_locked is True


@pytest.mark.asyncio
async def test_apply_social_does_not_overwrite_existing_id(db_session, test_user):
    test_user.discord_id = "already_set"
    apply_social_verified_and_locked(test_user, "discord", "other")
    assert test_user.discord_id == "already_set"
    assert test_user.discord_id_verified is True
    assert test_user.discord_id_locked is True


@pytest.mark.asyncio
async def test_revoke_platform_mission_rewards_removes_mission_and_ledger(
    db_session, test_user
):
    mid = uuid.uuid4()
    mission = models.Mission(
        id=mid,
        code="T_DISCORD_LOCK",
        title="Test Discord",
        description=None,
        link=None,
        icon="discord",
        type=models.MissionType.SOCIAL,
        reward_amount=1000.0,
        is_active=True,
    )
    db_session.add(mission)
    um = models.UserMission(
        user_id=test_user.id,
        mission_id=mid,
        status="COMPLETED",
        verification_proof="x",
    )
    db_session.add(um)
    test_user.balance = 1000.0
    test_user.total_earnings = 1000.0
    db_session.add(test_user)
    await db_session.commit()

    revoked = await revoke_platform_mission_rewards(
        db_session, test_user, "discord", "social_id_changed", extra_detail="test"
    )
    assert revoked == 1000.0
    await db_session.commit()
    await db_session.refresh(test_user)

    assert test_user.balance == 0.0
    assert test_user.total_earnings == 0.0

    r = await db_session.execute(
        select(models.UserMission).where(models.UserMission.mission_id == mid)
    )
    assert r.scalars().first() is None

    led = await db_session.execute(
        select(models.EarningsLedger).where(models.EarningsLedger.user_id == test_user.id)
    )
    entries = led.scalars().all()
    assert any(e.amount < 0 for e in entries)


@pytest.mark.asyncio
async def test_create_reward_entry_commits_balance(db_session, test_user):
    entry = await EarningsManager.create_reward_entry(
        user_id=test_user.id,
        amount=2.5,
        reward_type=models.RewardType.MISSION_COMPLETION,
        description="unit",
        db=db_session,
    )
    assert entry.amount == 2.5
    await db_session.refresh(test_user)
    assert test_user.balance == 2.5


@pytest.mark.asyncio
async def test_profile_change_verified_discord_requires_confirm(db_session, test_user):
    from database import get_db
    import auth as auth_module

    test_user.discord_id = "old_handle"
    test_user.discord_id_verified = True
    test_user.discord_id_locked = True
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
                json={"discord_id": "new_handle"},
            )
        assert r.status_code == 409
        detail = r.json()["detail"]
        assert detail["error_code"] == "SOCIAL_ID_CHANGE_REQUIRES_CONFIRMATION"
        assert "discord" in detail["platforms"]
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)


@pytest.mark.asyncio
async def test_profile_change_with_confirm_revokes_and_unlocks(db_session, test_user):
    from database import get_db
    import auth as auth_module

    mid = uuid.uuid4()
    mission = models.Mission(
        id=mid,
        code="T_DISCORD_LOCK2",
        title="Test Discord 2",
        description=None,
        link=None,
        icon="discord",
        type=models.MissionType.SOCIAL,
        reward_amount=500.0,
        is_active=True,
    )
    db_session.add(mission)
    um = models.UserMission(
        user_id=test_user.id,
        mission_id=mid,
        status="COMPLETED",
        verification_proof="p",
    )
    db_session.add(um)
    test_user.discord_id = "old_handle"
    test_user.discord_id_verified = True
    test_user.discord_id_locked = True
    test_user.balance = 500.0
    test_user.total_earnings = 500.0
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
                json={
                    "discord_id": "new_handle",
                    "confirm_social_reward_revocation": True,
                },
            )
        assert r.status_code == 200
        data = r.json()
        assert data["discord_id"] == "new_handle"
        assert data["discord_id_verified"] is False
        assert data["discord_id_locked"] is False

        await db_session.refresh(test_user)
        assert test_user.balance == 0.0

        r2 = await db_session.execute(
            select(models.UserMission).where(models.UserMission.mission_id == mid)
        )
        assert r2.scalars().first() is None
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)
