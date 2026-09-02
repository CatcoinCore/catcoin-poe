import asyncio
import logging
from sqlalchemy import text
from database import async_engine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def upgrade():
    columns = [
        ("can_withdraw_mining", "BOOLEAN DEFAULT FALSE"),
        ("can_withdraw_referrals", "BOOLEAN DEFAULT FALSE"),
        ("can_withdraw_missions", "BOOLEAN DEFAULT FALSE"),
        ("can_withdraw_games", "BOOLEAN DEFAULT FALSE"),
        ("can_withdraw_game_boosts", "BOOLEAN DEFAULT FALSE"),
    ]
    
    for col, col_type in columns:
        async with async_engine.begin() as conn:
            try:
                await conn.execute(text(f"ALTER TABLE users ADD COLUMN {col} {col_type}"))
                logger.info(f"Added column {col} to users")
            except Exception as e:
                if "already exists" in str(e).lower():
                    logger.info(f"Column {col} already exists, skipping")
                else:
                    logger.warning(f"Error adding {col}: {e}")

if __name__ == "__main__":
    asyncio.run(upgrade())
