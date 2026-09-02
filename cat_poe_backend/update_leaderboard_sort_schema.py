"""Add admin_config.leaderboard_sort_by if missing (ORM + API depend on it; was only in main.py startup before)."""

import asyncio
from sqlalchemy import text

from database import async_engine


async def migrate() -> None:
    print("Ensuring public.admin_config.leaderboard_sort_by exists...")
    async with async_engine.begin() as conn:
        await conn.execute(
            text(
                "ALTER TABLE public.admin_config "
                "ADD COLUMN IF NOT EXISTS leaderboard_sort_by VARCHAR DEFAULT 'BALANCE'"
            )
        )
    print("Done.")


if __name__ == "__main__":
    asyncio.run(migrate())
