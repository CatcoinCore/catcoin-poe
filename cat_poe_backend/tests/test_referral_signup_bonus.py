"""Referral signup credits Catoshi after email verification."""

import random
import uuid

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.future import select

import models
from database import get_db
from main import app


@pytest.fixture
def _clear_rate_buckets():
    from services import auth_rate_limit

    auth_rate_limit._timestamps.clear()
    yield
    auth_rate_limit._timestamps.clear()


@pytest.mark.asyncio
async def test_verify_email_grants_referral_bonuses(
    db_session, test_user_password_hash, test_admin_config, _clear_rate_buckets
):
    """New user with valid referred_by gets referee bonus; referrer gets invite bonus."""
    rid = uuid.uuid4().hex[:8]
    referrer_username = str(random.randint(900200000, 999899999))
    referrer = models.User(
        username=referrer_username,
        email=f"ref_{rid}@t.com",
        hashed_password=test_user_password_hash,
        referral_code=f"rb{rid}",
        balance=0.0,
        email_verified=True,
    )
    db_session.add(referrer)
    await db_session.commit()
    await db_session.refresh(referrer)

    test_admin_config.referral_signup_bonus_referee_amount = 100.0
    test_admin_config.referral_signup_bonus_referrer_amount = 50.0
    await db_session.commit()

    uid = uuid.uuid4().hex[:8]
    email = f"new_{uid}@t.com"
    body = {
        "email": email,
        "password": "SecurePass1!",
        "referred_by": referrer.referral_code.upper(),
    }

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            su = await client.post("/auth/signup", json=body)
            assert su.status_code == 200

        r = await db_session.execute(select(models.User).where(models.User.email == email))
        invitee = r.scalars().first()
        assert invitee is not None
        assert invitee.referred_by == referrer.referral_code.lower()
        code = invitee.verification_code
        assert code and len(code) == 6

        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            vr = await client.post(
                "/auth/verify-email",
                json={"email": email, "code": code},
            )
            assert vr.status_code == 200

        await db_session.refresh(invitee)
        await db_session.refresh(referrer)

        assert invitee.balance == pytest.approx(100.0)
        assert invitee.email_verified is True
        assert referrer.balance == pytest.approx(50.0)

        led = await db_session.execute(
            select(models.EarningsLedger).where(
                models.EarningsLedger.user_id == invitee.id,
                models.EarningsLedger.reward_type
                == models.RewardType.REFERRAL_SIGNUP_BONUS,
            )
        )
        rows = led.scalars().all()
        assert len(rows) >= 1
        assert any("Welcome bonus" in (x.description or "") for x in rows)
    finally:
        app.dependency_overrides.pop(get_db, None)
