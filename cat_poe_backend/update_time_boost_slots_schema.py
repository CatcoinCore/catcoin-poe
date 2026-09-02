"""Ensure mining_sessions.time_boost_slots_data exists (ORM JSON state for ad time boosts)."""

import asyncio
from sqlalchemy import text

from database import async_engine


async def migrate() -> None:
    print(
        "Running Migration: Ensuring public.mining_sessions.time_boost_slots_data exists..."
    )
    async with async_engine.begin() as conn:
        await conn.execute(
            text(
                "ALTER TABLE public.mining_sessions "
                "ADD COLUMN IF NOT EXISTS time_boost_slots_data VARCHAR"
            )
        )
    print("Successfully ensured time_boost_slots_data on mining_sessions.")


if __name__ == "__main__":
    asyncio.run(migrate())
