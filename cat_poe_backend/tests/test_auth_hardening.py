"""Tests for refresh rotation, OTP separation, rate limits, and enumeration-resistant auth."""

import random
import uuid

import pytest
from datetime import datetime, timedelta
from httpx import ASGITransport, AsyncClient
from sqlalchemy.future import select

import models
import auth as auth_module
from database import get_db
from main import app
from services import auth_messages
from services import auth_rate_limit


@pytest.fixture
def _clear_rate_buckets():
    auth_rate_limit._timestamps.clear()
    yield
    auth_rate_limit._timestamps.clear()


@pytest.mark.asyncio
async def test_refresh_rotation_then_replay_revokes_family(
    db_session, test_user, _clear_rate_buckets
):
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            login = await client.post(
                "/auth/login",
                data={
                    "username": test_user.username,
                    "password": "testpassword",
                },
            )
            assert login.status_code == 200
            r1 = login.json()["refresh_token"]

            ref1 = await client.post(
                "/auth/refresh", json={"refresh_token": r1}
            )
            assert ref1.status_code == 200
            r2 = ref1.json()["refresh_token"]
            assert r2 != r1

            ref_old = await client.post(
                "/auth/refresh", json={"refresh_token": r1}
            )
            assert ref_old.status_code == 401
            assert (
                ref_old.json()["detail"] == auth_messages.INVALID_REFRESH_TOKEN
            )

            ref_stale = await client.post(
                "/auth/refresh", json={"refresh_token": r2}
            )
            assert ref_stale.status_code == 401

            login2 = await client.post(
                "/auth/login",
                data={
                    "username": test_user.username,
                    "password": "testpassword",
                },
            )
            assert login2.status_code == 200
            r3 = login2.json()["refresh_token"]
            ref3 = await client.post(
                "/auth/refresh", json={"refresh_token": r3}
            )
            assert ref3.status_code == 200
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_signup_duplicate_verified_returns_generic_ack(
    db_session, test_user_password_hash, _clear_rate_buckets
):
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    uid = uuid.uuid4().hex[:10]
    email = f"vdup_{uid}@example.com"
    existing = models.User(
        username=str(random.randint(900200000, 999899999)),
        email=email,
        hashed_password=test_user_password_hash,
        referral_code=f"vdp{uid[:8]}",
        email_verified=True,
    )
    db_session.add(existing)
    await db_session.commit()

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.post(
                "/auth/signup",
                json={
                    "email": email,
                    "password": "SecurePass1!",
                    "referred_by": None,
                },
            )
            assert r.status_code == 200
            assert r.json()["message"] == auth_messages.SIGNUP_ACK
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_signup_duplicate_unverified_updates_password_and_message(
    db_session, _clear_rate_buckets
):
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    uid = uuid.uuid4().hex[:10]
    email = f"odup_{uid}@example.com"
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            first = await client.post(
                "/auth/signup",
                json={
                    "email": email,
                    "password": "SecurePass1!",
                    "referred_by": None,
                },
            )
            assert first.status_code == 200
            assert first.json()["message"] == auth_messages.SIGNUP_ACK

            dup = await client.post(
                "/auth/signup",
                json={
                    "email": email,
                    "password": "DifferentPass9!",
                    "referred_by": None,
                },
            )
            assert dup.status_code == 200
            assert dup.json()["message"] == auth_messages.SIGNUP_EXISTING_UNVERIFIED_ACK

            res = await db_session.execute(
                select(models.User).where(models.User.email == email)
            )
            row = res.scalars().first()
            assert row is not None
            code = row.verification_code
            assert code and len(code) == 6

            vr = await client.post(
                "/auth/verify-email",
                json={"email": email, "code": code},
            )
            assert vr.status_code == 200

            ok = await client.post(
                "/auth/login",
                data={"username": email, "password": "DifferentPass9!"},
            )
            assert ok.status_code == 200

            bad = await client.post(
                "/auth/login",
                data={"username": email, "password": "SecurePass1!"},
            )
            assert bad.status_code == 401
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_forgot_password_unknown_email_ack(db_session, _clear_rate_buckets):
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.post(
                "/auth/forgot-password",
                json={"email": f"missing_{uuid.uuid4().hex}@example.com"},
            )
            assert r.status_code == 200
            assert r.json()["message"] == auth_messages.FORGOT_PASSWORD_ACK
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_verify_email_ignores_password_reset_channel(db_session):
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    uid = uuid.uuid4().hex[:8]
    user = models.User(
        username=f"v_{uid}",
        email=f"v_{uid}@example.com",
        hashed_password=auth_module.get_password_hash("x"),
        referral_code=f"VR{uid}",
        email_verified=False,
        verification_code=None,
        verification_code_expires=None,
        password_reset_code="123456",
        password_reset_expires=datetime.utcnow() + timedelta(minutes=10),
    )
    db_session.add(user)
    await db_session.commit()

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.post(
                "/auth/verify-email",
                json={"email": user.email, "code": "123456"},
            )
            assert r.status_code == 400
            assert r.json()["detail"] == auth_messages.INVALID_VERIFICATION_CODE
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_reset_password_expired_code(db_session):
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    uid = uuid.uuid4().hex[:8]
    user = models.User(
        username=f"r_{uid}",
        email=f"r_{uid}@example.com",
        hashed_password=auth_module.get_password_hash("oldpass1"),
        referral_code=f"RR{uid}",
        email_verified=True,
        password_reset_code="999888",
        password_reset_expires=datetime.utcnow() - timedelta(minutes=1),
    )
    db_session.add(user)
    await db_session.commit()

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.post(
                "/auth/reset-password",
                json={
                    "email": user.email,
                    "code": "999888",
                    "new_password": "Newsecure1!",
                },
            )
            assert r.status_code == 400
            assert r.json()["detail"] == auth_messages.INVALID_RESET_CODE
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_reset_password_does_not_accept_verification_code(db_session):
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    uid = uuid.uuid4().hex[:8]
    user = models.User(
        username=f"w_{uid}",
        email=f"w_{uid}@example.com",
        hashed_password=auth_module.get_password_hash("oldpass1"),
        referral_code=f"WR{uid}",
        email_verified=False,
        verification_code="111222",
        verification_code_expires=datetime.utcnow() + timedelta(minutes=10),
        password_reset_code=None,
        password_reset_expires=None,
    )
    db_session.add(user)
    await db_session.commit()

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.post(
                "/auth/reset-password",
                json={
                    "email": user.email,
                    "code": "111222",
                    "new_password": "Newsecure1!",
                },
            )
            assert r.status_code == 400
            assert r.json()["detail"] == auth_messages.INVALID_RESET_CODE
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_signup_rate_limit_returns_429(db_session, monkeypatch, _clear_rate_buckets):
    from config import settings

    monkeypatch.delenv("DISABLE_AUTH_RATE_LIMIT", raising=False)
    monkeypatch.setattr(settings, "DISABLE_AUTH_RATE_LIMIT", False)
    monkeypatch.setattr(settings, "AUTH_RL_SIGNUP_PER_HOUR_IP", 2)

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            for i in range(2):
                email = f"rl_{uuid.uuid4().hex}@example.com"
                resp = await client.post(
                    "/auth/signup",
                    json={
                        "email": email,
                        "password": "SecurePass1!",
                        "referred_by": None,
                    },
                )
                assert resp.status_code == 200, resp.text

            blocked = await client.post(
                "/auth/signup",
                json={
                    "email": f"rl_{uuid.uuid4().hex}@example.com",
                    "password": "SecurePass1!",
                    "referred_by": None,
                },
            )
            assert blocked.status_code == 429
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_reset_password_rate_limit_returns_429(
    db_session, monkeypatch, _clear_rate_buckets
):
    from config import settings

    monkeypatch.delenv("DISABLE_AUTH_RATE_LIMIT", raising=False)
    monkeypatch.setattr(settings, "DISABLE_AUTH_RATE_LIMIT", False)
    monkeypatch.setattr(settings, "AUTH_RL_RESET_PER_MINUTE_IP", 2)

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    uid = uuid.uuid4().hex[:8]
    user = models.User(
        username=f"rlr_{uid}",
        email=f"rlr_{uid}@example.com",
        hashed_password=auth_module.get_password_hash("p"),
        referral_code=f"RLR{uid}",
        email_verified=True,
        password_reset_code="888777",
        password_reset_expires=datetime.utcnow() + timedelta(minutes=10),
    )
    db_session.add(user)
    await db_session.commit()

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            for _ in range(2):
                resp = await client.post(
                    "/auth/reset-password",
                    json={
                        "email": user.email,
                        "code": "wrong",
                        "new_password": "Nope12345!",
                    },
                )
                assert resp.status_code == 400

            blocked = await client.post(
                "/auth/reset-password",
                json={
                    "email": user.email,
                    "code": "wrong",
                    "new_password": "Nope12345!",
                },
            )
            assert blocked.status_code == 429
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_verify_email_rate_limit_returns_429(
    db_session, monkeypatch, _clear_rate_buckets
):
    from config import settings

    monkeypatch.delenv("DISABLE_AUTH_RATE_LIMIT", raising=False)
    monkeypatch.setattr(settings, "DISABLE_AUTH_RATE_LIMIT", False)
    monkeypatch.setattr(settings, "AUTH_RL_VERIFY_PER_MINUTE_IP", 2)

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    uid = uuid.uuid4().hex[:8]
    user = models.User(
        username=f"rlv_{uid}",
        email=f"rlv_{uid}@example.com",
        hashed_password=auth_module.get_password_hash("p"),
        referral_code=f"RLV{uid}",
        email_verified=False,
        verification_code="123456",
        verification_code_expires=datetime.utcnow() + timedelta(minutes=10),
    )
    db_session.add(user)
    await db_session.commit()

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            for _ in range(2):
                resp = await client.post(
                    "/auth/verify-email",
                    json={"email": user.email, "code": "000000"},
                )
                assert resp.status_code == 400

            blocked = await client.post(
                "/auth/verify-email",
                json={"email": user.email, "code": "000000"},
            )
            assert blocked.status_code == 429
    finally:
        app.dependency_overrides.pop(get_db, None)
