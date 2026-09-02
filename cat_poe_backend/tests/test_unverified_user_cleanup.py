"""Stale unverified-user cleanup."""

import random
import uuid
from datetime import datetime, timedelta

import pytest
from sqlalchemy.future import select

import models
from services.unverified_user_cleanup import delete_stale_unverified_users
from config import settings


@pytest.mark.asyncio
async def test_deletes_stale_unverified_zero_balance(
    db_session, test_user_password_hash, monkeypatch
):
    monkeypatch.setattr(settings, "UNVERIFIED_USER_RETENTION_HOURS", 8)

    rid = uuid.uuid4().hex[:8]
    u = models.User(
        username=str(random.randint(900200000, 999899999)),
        email=f"stale_cleanup_{rid}@example.com",
        hashed_password=test_user_password_hash,
        referral_code=f"sc{rid}",
        balance=0.0,
        total_earnings=0.0,
        email_verified=False,
        verification_code="111111",
        verification_code_expires=datetime.utcnow() + timedelta(minutes=5),
        created_at=datetime.utcnow() - timedelta(hours=9),
    )
    db_session.add(u)
    await db_session.commit()
    await db_session.refresh(u)

    n = await delete_stale_unverified_users(db_session)
    assert n == 1

    again = await db_session.execute(select(models.User).where(models.User.id == u.id))
    assert again.scalars().first() is None


@pytest.mark.asyncio
async def test_skips_recent_unverified(
    db_session, test_user_password_hash, monkeypatch
):
    monkeypatch.setattr(settings, "UNVERIFIED_USER_RETENTION_HOURS", 8)

    rid = uuid.uuid4().hex[:8]
    u = models.User(
        username=str(random.randint(900200000, 999899999)),
        email=f"fresh_cleanup_{rid}@example.com",
        hashed_password=test_user_password_hash,
        referral_code=f"s2{rid}",
        balance=0.0,
        total_earnings=0.0,
        email_verified=False,
        verification_code="222222",
        verification_code_expires=datetime.utcnow() + timedelta(minutes=5),
        created_at=datetime.utcnow() - timedelta(hours=1),
    )
    db_session.add(u)
    await db_session.commit()

    n = await delete_stale_unverified_users(db_session)
    assert n == 0


@pytest.mark.asyncio
async def test_skips_unverified_with_balance(
    db_session, test_user_password_hash, monkeypatch
):
    monkeypatch.setattr(settings, "UNVERIFIED_USER_RETENTION_HOURS", 8)

    rid = uuid.uuid4().hex[:8]
    u = models.User(
        username=str(random.randint(900200000, 999899999)),
        email=f"rich_cleanup_{rid}@example.com",
        hashed_password=test_user_password_hash,
        referral_code=f"s3{rid}",
        balance=1.0,
        total_earnings=0.0,
        email_verified=False,
        verification_code="333333",
        verification_code_expires=datetime.utcnow() + timedelta(minutes=5),
        created_at=datetime.utcnow() - timedelta(hours=9),
    )
    db_session.add(u)
    await db_session.commit()
    uid = u.id

    n = await delete_stale_unverified_users(db_session)
    assert n == 0

    still = await db_session.execute(select(models.User).where(models.User.id == uid))
    assert still.scalars().first() is not None


@pytest.mark.asyncio
async def test_skips_old_but_verified(
    db_session, test_user_password_hash, monkeypatch
):
    monkeypatch.setattr(settings, "UNVERIFIED_USER_RETENTION_HOURS", 8)

    rid = uuid.uuid4().hex[:8]
    u = models.User(
        username=str(random.randint(900200000, 999899999)),
        email=f"verified_old_{rid}@example.com",
        hashed_password=test_user_password_hash,
        referral_code=f"s4{rid}",
        balance=0.0,
        total_earnings=0.0,
        email_verified=True,
        created_at=datetime.utcnow() - timedelta(hours=9),
    )
    db_session.add(u)
    await db_session.commit()
    uid = u.id

    n = await delete_stale_unverified_users(db_session)
    assert n == 0

    still = await db_session.execute(select(models.User).where(models.User.id == uid))
    assert still.scalars().first() is not None
