import asyncio
import logging
from sqlalchemy import text
from database import async_engine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def upgrade() -> None:
    async with async_engine.begin() as conn:
        logger.info("Adding global_push_message to admin_config...")
        await conn.execute(
            text(
                "ALTER TABLE admin_config "
                "ADD COLUMN IF NOT EXISTS global_push_message VARCHAR"
            )
        )
        logger.info("Processed global_push_message")

if __name__ == "__main__":
    asyncio.run(upgrade())
