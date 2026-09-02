import asyncio
import logging
from sqlalchemy import text
from database import AsyncSessionLocal, async_engine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def migrate():
    try:
        async with AsyncSessionLocal() as db:
            logger.info("Adding game_ads_enabled column to admin_config table...")
            try:
                await db.execute(text("ALTER TABLE admin_config ADD COLUMN game_ads_enabled BOOLEAN DEFAULT FALSE;"))
                await db.commit()
                logger.info("Column added successfully.")
            except Exception as e:
                await db.rollback()
                if "already exists" in str(e).lower() or "duplicate column" in str(e).lower():
                    logger.info("Column game_ads_enabled already exists.")
                else:
                    logger.error(f"Error adding column: {e}")
                    raise e
    finally:
        await async_engine.dispose()

if __name__ == "__main__":
    asyncio.run(migrate())

