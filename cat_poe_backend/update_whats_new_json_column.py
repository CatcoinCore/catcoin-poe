import asyncio
import logging
from sqlalchemy import text

from database import async_engine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def upgrade() -> None:
    async with async_engine.begin() as conn:
        logger.info("Adding whats_new_json to admin_config...")
        await conn.execute(
            text(
                "ALTER TABLE admin_config ADD COLUMN IF NOT EXISTS "
                "whats_new_json JSONB DEFAULT '[]'::jsonb"
            )
        )
        logger.info("Processed whats_new_json")


if __name__ == "__main__":
    asyncio.run(upgrade())
