"""Adds visibility flag and merges TILE_SWAP into game_reward_config."""

import asyncio
import json
import logging

from sqlalchemy import text

from admin_config_defaults import DEFAULT_GAME_REWARD_CONFIG_JSON
from database import async_engine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

NEW_GAME_TYPES = ("TILE_SWAP",)


async def upgrade() -> None:
    async with async_engine.begin() as conn:
        logger.info("Adding Tile Swap visibility column to admin_config...")
        await conn.execute(
            text(
                "ALTER TABLE admin_config "
                "ADD COLUMN IF NOT EXISTS is_tile_swap_game_visible BOOLEAN DEFAULT TRUE"
            )
        )
        logger.info("Processed is_tile_swap_game_visible")

        result = await conn.execute(
            text("SELECT game_reward_config FROM admin_config WHERE id = 1")
        )
        row = result.mappings().first()
        if not row:
            logger.info(
                "No admin_config row with id=1 yet; seed_admin_game_config.py "
                "will populate it."
            )
            return

        existing_raw = row["game_reward_config"]
        if not existing_raw or not str(existing_raw).strip():
            logger.info(
                "game_reward_config is empty; leaving for seed_admin_game_config.py."
            )
            return

        try:
            existing = json.loads(existing_raw)
        except json.JSONDecodeError:
            logger.warning(
                "game_reward_config is not valid JSON; skipping merge so admins can "
                "fix it manually."
            )
            return

        defaults = json.loads(DEFAULT_GAME_REWARD_CONFIG_JSON)
        added = []
        for gtype in NEW_GAME_TYPES:
            if gtype not in existing and gtype in defaults:
                existing[gtype] = defaults[gtype]
                added.append(gtype)

        if added:
            await conn.execute(
                text(
                    "UPDATE admin_config SET game_reward_config = :json WHERE id = 1"
                ),
                {"json": json.dumps(existing)},
            )
            logger.info("Merged %s into game_reward_config", ", ".join(added))
        else:
            logger.info("game_reward_config already lists TILE_SWAP.")


if __name__ == "__main__":
    asyncio.run(upgrade())
