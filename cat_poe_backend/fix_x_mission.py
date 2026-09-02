import asyncio
import os
import sys

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

import script_env  # noqa: F401


def _database_url() -> str:
    url = os.getenv("DATABASE_URL", "").strip()
    if not url:
        print("DATABASE_URL is required (see .env.example).", file=sys.stderr)
        sys.exit(1)
    return url


async def main():
    engine = create_async_engine(_database_url(), echo=True)
    async_session = sessionmaker(
        bind=engine, class_=AsyncSession, expire_on_commit=False
    )

    async with async_session() as db:
        print("Fixing X Mission...")

        await db.execute(
            text("""
            UPDATE missions
            SET title = 'Follow @catcoin',
                description = 'Follow our official X account @catcoin for latest news.',
                link = 'https://x.com/i/communities/YOUR_COMMUNITY_ID'
            WHERE code = 'FOLLOW_X'
            """)
        )

        await db.execute(
            text("""
            UPDATE admin_config
            SET x_community_username = 'YOUR_COMMUNITY_ID'
            WHERE id = 1
            """)
        )

        await db.commit()
        print("X Mission updated. Config updated.")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
