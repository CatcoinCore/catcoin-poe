from sqlalchemy import create_engine
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
from config import settings

# Async setup
ASYNC_SQLALCHEMY_DATABASE_URL = settings.DATABASE_URL
async_engine = create_async_engine(
    ASYNC_SQLALCHEMY_DATABASE_URL,
    echo=False,
)
AsyncSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=async_engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# Sync setup
SYNC_SQLALCHEMY_DATABASE_URL = (ASYNC_SQLALCHEMY_DATABASE_URL or "").replace("+asyncpg", "")
sync_engine = create_engine(
    SYNC_SQLALCHEMY_DATABASE_URL,
    echo=False,
)
SyncSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=sync_engine,
    expire_on_commit=False
)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
