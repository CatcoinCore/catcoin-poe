import pytest
import asyncio
import re
from datetime import datetime, timedelta

import asyncpg
from asyncpg.exceptions import DuplicateDatabaseError
from sqlalchemy import text
from sqlalchemy.engine.url import make_url
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import NullPool

from database import Base
from config import settings
import models
from admin_config_defaults import (
    DEFAULT_GAME_BOOST_CONFIG_JSON,
    DEFAULT_GAME_REWARD_CONFIG_JSON,
)

import os

# Avoid flaky CI when many tests hit auth endpoints (in-process rate limits).
os.environ.setdefault("DISABLE_AUTH_RATE_LIMIT", "1")

# Test database URL — derive from app DATABASE_URL or use Docker default
_app_db_url = os.environ.get(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:password@localhost/catcoin_poe"
)
# Swap to test database name
TEST_DATABASE_URL = _app_db_url.rsplit("/", 1)[0] + "/catcoin_poe_test"


async def _ensure_test_database_catalog_exists() -> None:
    """Create the test DB if missing (Docker initdb only runs on a fresh Postgres volume)."""
    url = make_url(TEST_DATABASE_URL)
    dbname = url.database
    if not dbname or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", dbname):
        raise ValueError(f"Unsafe or missing test database name in URL: {dbname!r}")

    conn = await asyncpg.connect(
        host=url.host or "localhost",
        port=url.port or 5432,
        user=url.username,
        password=url.password or "",
        database="postgres",
    )
    try:
        await conn.execute(f"CREATE DATABASE {dbname}")
    except DuplicateDatabaseError:
        pass
    finally:
        await conn.close()


# Create test engine
test_engine = create_async_engine(
    TEST_DATABASE_URL,
    poolclass=NullPool,
    echo=False
)

# Create test session factory
TestSessionLocal = sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False
)


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for the test session"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
async def setup_database():
    """Create test database tables"""
    await _ensure_test_database_catalog_exists()
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture(scope="session")
def test_user_password_hash():
    """Valid bcrypt hash for the shared test login password."""
    from auth import get_password_hash

    return get_password_hash("testpassword")


async def _truncate_all_tables():
    """Remove all rows between tests so commits do not leak across tests."""
    async with TestSessionLocal() as session:
        names = ", ".join(f'"{t.name}"' for t in Base.metadata.sorted_tables)
        if names:
            await session.execute(
                text(f"TRUNCATE TABLE {names} RESTART IDENTITY CASCADE")
            )
            await session.commit()


@pytest.fixture
async def db_session(setup_database):
    """Provide a DB session; truncate all tables after each test."""
    async with TestSessionLocal() as session:
        yield session
    await _truncate_all_tables()


@pytest.fixture
async def dual_db_sessions(setup_database):
    """Two independent async sessions (separate connections), for advisory-lock tests."""
    async with TestSessionLocal() as s1, TestSessionLocal() as s2:
        yield s1, s2
    await _truncate_all_tables()


@pytest.fixture
async def test_user(db_session, test_user_password_hash):
    """Create a test user (verified email + valid bcrypt for login tests)."""
    import uuid

    uid = uuid.uuid4().hex[:8]
    user = models.User(
        username=f"testuser_{uid}",
        email=f"testuser_{uid}@test.com",
        hashed_password=test_user_password_hash,
        referral_code=f"TREF{uid}",
        balance=0.0,
        email_verified=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
async def admin_user(db_session, test_user_password_hash):
    """Admin user for protected admin API tests."""
    import uuid

    uid = uuid.uuid4().hex[:8]
    u = models.User(
        username=f"admin_{uid}",
        email=f"admin_{uid}@test.com",
        hashed_password=test_user_password_hash,
        referral_code=f"ADM{uid}",
        balance=0.0,
        email_verified=True,
        is_admin=True,
    )
    db_session.add(u)
    await db_session.commit()
    await db_session.refresh(u)
    return u


@pytest.fixture
async def test_admin_config(db_session):
    """Ensure a row with id=1 exists (SessionManager.get_admin_config may create one first)."""
    result = await db_session.execute(
        select(models.AdminConfig).where(models.AdminConfig.id == 1)
    )
    existing = result.scalars().first()
    if existing:
        return existing
    config = models.AdminConfig(
        id=1,
        base_hashrate=100.0,
        time_boost_duration_seconds=14400,  # 4 hours
        speed_boost_per_referral=10.0,
        game_boost_config=DEFAULT_GAME_BOOST_CONFIG_JSON,
        game_reward_config=DEFAULT_GAME_REWARD_CONFIG_JSON,
    )
    db_session.add(config)
    await db_session.commit()
    await db_session.refresh(config)
    return config


@pytest.fixture
async def test_mining_session(db_session, test_user, test_admin_config):
    """Create a test mining session"""
    now = datetime.utcnow()
    session = models.MiningSession(
        user_id=test_user.id,
        session_type=models.SessionType.BASE,
        start_time=now,
        end_time=now + timedelta(hours=4),
        status=models.MiningStatus.ACTIVE,
        reward_y=1000,
        reward_t=1,
    )
    db_session.add(session)
    await db_session.commit()
    await db_session.refresh(session)
    return session


@pytest.fixture
async def expired_mining_session(db_session, test_user, test_admin_config):
    """Create an expired mining session"""
    now = datetime.utcnow()
    session = models.MiningSession(
        user_id=test_user.id,
        session_type=models.SessionType.BASE,
        start_time=now - timedelta(hours=5),
        end_time=now - timedelta(hours=1),  # Expired 1 hour ago
        status=models.MiningStatus.ACTIVE,
        total_earned=0.0,
        reward_y=1000,
        reward_t=1,
    )
    db_session.add(session)
    await db_session.commit()
    await db_session.refresh(session)
    return session
