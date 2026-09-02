import asyncio
import logging
from sqlalchemy import text
from database import async_engine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def upgrade():
    async with async_engine.begin() as conn:
        logger.info("Adding new game visibility columns to admin_config...")
        await conn.execute(text("ALTER TABLE admin_config ADD COLUMN IF NOT EXISTS is_sudoku_game_visible BOOLEAN DEFAULT TRUE"))
        logger.info("Processed is_sudoku_game_visible")

        await conn.execute(text("ALTER TABLE admin_config ADD COLUMN IF NOT EXISTS is_collage_game_visible BOOLEAN DEFAULT TRUE"))
        logger.info("Processed is_collage_game_visible")

        logger.info("Adding game_type column to game_sessions...")
        await conn.execute(text("ALTER TABLE game_sessions ADD COLUMN IF NOT EXISTS game_type VARCHAR DEFAULT 'RUNNER'"))
        logger.info("Processed game_type in game_sessions")

if __name__ == "__main__":
    asyncio.run(upgrade())
