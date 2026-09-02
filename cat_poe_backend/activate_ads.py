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
    ad_unit_id = os.getenv("ANDROID_AD_UNIT_ID", "").strip()
    if not ad_unit_id:
        print("ANDROID_AD_UNIT_ID is required.", file=sys.stderr)
        sys.exit(1)

    engine = create_async_engine(_database_url(), echo=True)
    async_session = sessionmaker(
        bind=engine, class_=AsyncSession, expire_on_commit=False
    )

    async with async_session() as db:
        print("Updating Ad Configuration...")

        await db.execute(
            text("""
            UPDATE admin_config
            SET android_ad_unit_id = :ad_id,
                ad_required_for_mining_start = true,
                ad_required_for_speed_boost = true,
                ad_required_for_time_boost = true
            WHERE id = 1
            """),
            {"ad_id": ad_unit_id},
        )

        await db.commit()
        print(f"AdminConfig updated: Android Ad Unit ID set.")
        print("Ads enabled for Mining Start, Speed Boost, and Time Boost.")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
