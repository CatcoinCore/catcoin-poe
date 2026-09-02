"""
Backfill admin_config.game_boost_config and game_reward_config when NULL or blank.

Run once after deploy or when adding a new environment:
    python seed_admin_game_config.py

Uses raw SQL for only these columns so lagging DB schemas (missing other admin_config
columns vs models.py) do not break this script.

Idempotent: only fills empty fields; does not overwrite admin-customized JSON.
"""

import asyncio

from sqlalchemy import text

from admin_config_defaults import (
    DEFAULT_GAME_BOOST_CONFIG_JSON,
    DEFAULT_GAME_REWARD_CONFIG_JSON,
)
from database import async_engine


async def seed() -> None:
    async with async_engine.begin() as conn:
        await conn.execute(
            text(
                "ALTER TABLE public.admin_config "
                "ADD COLUMN IF NOT EXISTS game_boost_config TEXT"
            )
        )
        await conn.execute(
            text(
                "ALTER TABLE public.admin_config "
                "ADD COLUMN IF NOT EXISTS game_reward_config TEXT"
            )
        )

        result = await conn.execute(
            text(
                "SELECT game_boost_config, game_reward_config "
                "FROM public.admin_config WHERE id = 1"
            )
        )
        row = result.mappings().first()
        if not row:
            print("No admin_config row with id=1. Create it first (e.g. open admin API or app).")
            return

        reward = row["game_reward_config"]
        boost = row["game_boost_config"]

        params: dict = {}
        sets: list[str] = []
        if not reward or not str(reward).strip():
            sets.append("game_reward_config = :game_reward_config")
            params["game_reward_config"] = DEFAULT_GAME_REWARD_CONFIG_JSON
            print("Set game_reward_config from admin_config_defaults.")
        if not boost or not str(boost).strip():
            sets.append("game_boost_config = :game_boost_config")
            params["game_boost_config"] = DEFAULT_GAME_BOOST_CONFIG_JSON
            print("Set game_boost_config from admin_config_defaults.")

        if not sets:
            print("Game config columns already populated; nothing to do.")
            return

        await conn.execute(
            text(f"UPDATE public.admin_config SET {', '.join(sets)} WHERE id = 1"),
            params,
        )
    print("Committed.")


if __name__ == "__main__":
    asyncio.run(seed())
