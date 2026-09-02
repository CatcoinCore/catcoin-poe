"""Admin referral list wrapper + referred_by assignment rules."""

import uuid
from datetime import datetime

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.exc import IntegrityError
from sqlalchemy.future import select

import auth as auth_module
import models
from database import get_db
from main import app
from services import auth_rate_limit
from services.referral_assignment import (
    REFERRAL_ERR_AFTER_ACTIVITY,
    REFERRAL_ERR_SELF,
    can_set_referred_by,
)
from services.referral_bonus import ensure_referral_row


@pytest.fixture
def _clear_rate_buckets():
    auth_rate_limit._timestamps.clear()
    yield
    auth_rate_limit._timestamps.clear()


@pytest.mark.asyncio
async def test_admin_referrals_list_wrapper_pagination_and_total(
    db_session, admin_user, test_user_password_hash
):
    """GET /v1/admin/referrals returns items, total, skip, limit; total matches filters."""
    rid = uuid.uuid4().hex[:8]
    ref_users = []
    for i in range(4):
        u = models.User(
            username=f"arl_{rid}_{i}",
            email=f"arl_{rid}_{i}@t.com",
            hashed_password=test_user_password_hash,
            referral_code=f"ARL{rid}{i}",
            balance=0.0,
            email_verified=True,
        )
        db_session.add(u)
        ref_users.append(u)
    await db_session.flush()

    for i, fee in enumerate(ref_users[1:]):
        db_session.add(
            models.Referral(
                referrer_user_id=ref_users[0].id,
                referee_user_id=fee.id,
                referred_at=datetime.utcnow(),
                bonus_status="pending",
            )
        )
    await db_session.commit()

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
            r = await client.get("/v1/admin/referrals", params={"skip": 1, "limit": 2})
            assert r.status_code == 200
            body = r.json()
            assert body["total"] == 3
            assert body["skip"] == 1
            assert body["limit"] == 2
            assert len(body["items"]) == 2

            r2 = await client.get(
                "/v1/admin/referrals",
                params={"referrer_user_id": str(ref_users[0].id)},
            )
            assert r2.status_code == 200
            b2 = r2.json()
            assert b2["total"] == 3
            assert len(b2["items"]) == 3
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)


@pytest.mark.asyncio
async def test_can_set_referred_by_rejects_after_game_reward(
    db_session, test_user_password_hash
):
    uid = uuid.uuid4().hex[:8]
    referrer = models.User(
        username=f"rg_{uid}",
        email=f"rg_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"RG{uid}",
        balance=0.0,
        email_verified=True,
    )
    referee = models.User(
        username=f"gf_{uid}",
        email=f"gf_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"GF{uid}",
        balance=0.0,
        email_verified=True,
    )
    db_session.add_all([referrer, referee])
    await db_session.flush()
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
            reward_catoshi=100,
        )
    )
    await db_session.commit()

    ok, err = await can_set_referred_by(
        db_session,
        referee,
        referrer=referrer,
        proposed_code_lower=referrer.referral_code.lower(),
    )
    assert ok is False
    assert err["error_code"] == REFERRAL_ERR_AFTER_ACTIVITY


@pytest.mark.asyncio
async def test_can_set_referred_by_rejects_after_mining_ledger(
    db_session, test_user_password_hash
):
    uid = uuid.uuid4().hex[:8]
    referrer = models.User(
        username=f"rb_{uid}",
        email=f"rb_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"RB{uid}",
        balance=0.0,
        email_verified=True,
    )
    referee = models.User(
        username=f"rf_{uid}",
        email=f"rf_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"RF{uid}",
        balance=0.0,
        email_verified=True,
    )
    db_session.add_all([referrer, referee])
    await db_session.flush()
    db_session.add(
        models.EarningsLedger(
            user_id=referee.id,
            amount=1.0,
            reward_type=models.RewardType.MINING_BASE,
        )
    )
    await db_session.commit()

    ok, err = await can_set_referred_by(
        db_session,
        referee,
        referrer=referrer,
        proposed_code_lower=referrer.referral_code.lower(),
    )
    assert ok is False
    assert err["error_code"] == REFERRAL_ERR_AFTER_ACTIVITY


@pytest.mark.asyncio
async def test_can_set_referred_by_rejects_self_code(
    db_session, test_user_password_hash
):
    uid = uuid.uuid4().hex[:8]
    u = models.User(
        username=f"slf_{uid}",
        email=f"slf_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"SLF{uid}",
        balance=0.0,
        email_verified=True,
    )
    db_session.add(u)
    await db_session.commit()

    ok, err = await can_set_referred_by(
        db_session,
        u,
        referrer=u,
        proposed_code_lower=u.referral_code.lower(),
    )
    assert ok is False
    assert err["error_code"] == REFERRAL_ERR_SELF


@pytest.mark.asyncio
async def test_duplicate_referrer_referee_pair_unique_constraint(
    db_session, test_user_password_hash
):
    uid = uuid.uuid4().hex[:8]
    referrer = models.User(
        username=f"dp_{uid}",
        email=f"dp_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"DP{uid}",
        balance=0.0,
        email_verified=True,
    )
    referee = models.User(
        username=f"dr_{uid}",
        email=f"dr_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"DR{uid}",
        balance=0.0,
        email_verified=True,
    )
    db_session.add_all([referrer, referee])
    await db_session.flush()
    db_session.add(
        models.Referral(
            referrer_user_id=referrer.id,
            referee_user_id=referee.id,
            referred_at=datetime.utcnow(),
        )
    )
    await db_session.commit()

    db_session.add(
        models.Referral(
            referrer_user_id=referrer.id,
            referee_user_id=referee.id,
            referred_at=datetime.utcnow(),
        )
    )
    with pytest.raises(IntegrityError):
        await db_session.commit()
    await db_session.rollback()


@pytest.mark.asyncio
async def test_ensure_referral_row_idempotent(
    db_session, test_user_password_hash
):
    uid = uuid.uuid4().hex[:8]
    referrer = models.User(
        username=f"id_{uid}",
        email=f"id_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"ID{uid}",
        balance=0.0,
        email_verified=True,
    )
    referee = models.User(
        username=f"ie_{uid}",
        email=f"ie_{uid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"IE{uid}",
        balance=0.0,
        email_verified=True,
    )
    db_session.add_all([referrer, referee])
    await db_session.commit()

    r1 = await ensure_referral_row(db_session, referrer, referee)
    r2 = await ensure_referral_row(db_session, referrer, referee)
    assert r1 is not None and r2 is not None
    assert r1.id == r2.id


@pytest.mark.asyncio
async def test_referred_by_endpoint_put_and_second_attempt_blocked(
    db_session, test_user_password_hash, test_admin_config, _clear_rate_buckets
):
    rid = uuid.uuid4().hex[:8]
    referrer = models.User(
        username=f"ep_{rid}",
        email=f"ep_{rid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"EP{rid}",
        balance=0.0,
        email_verified=True,
    )
    referee = models.User(
        username=f"ee_{rid}",
        email=f"ee_{rid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"EE{rid}",
        balance=0.0,
        email_verified=True,
    )
    db_session.add_all([referrer, referee])
    await db_session.commit()

    async def _db():
        yield db_session

    async def _referee():
        return referee

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[auth_module.get_current_user] = _referee
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.put(
                "/auth/users/me/referred-by",
                json={"referral_code": referrer.referral_code},
            )
            assert r.status_code == 200
            await db_session.refresh(referee)
            assert referee.referred_by == referrer.referral_code.lower()

            row = await db_session.execute(
                select(models.Referral).where(
                    models.Referral.referee_user_id == referee.id
                )
            )
            assert row.scalars().first() is not None

            r2 = await client.post(
                "/auth/users/me/referred-by",
                json={"referral_code": "OTHERCODE"},
            )
            assert r2.status_code == 400
            detail = r2.json()["detail"]
            assert detail["error_code"] == "referral_already_set"
    finally:
        app.dependency_overrides.pop(get_db, None)
        app.dependency_overrides.pop(auth_module.get_current_user, None)
