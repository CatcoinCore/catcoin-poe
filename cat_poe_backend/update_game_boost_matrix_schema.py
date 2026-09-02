import asyncio
from sqlalchemy import text

from admin_config_defaults import DEFAULT_GAME_BOOST_CONFIG_JSON
from database import AsyncSessionLocal

async def upgrade():
    async with AsyncSessionLocal() as session:
        try:
            # Check if column exists
            result = await session.execute(text(
                "SELECT column_name FROM information_schema.columns "
                "WHERE table_name='admin_config' AND column_name='game_boost_config'"
            ))
            if not result.scalar():
                print("Adding game_boost_config column to admin_config...")
                esc = DEFAULT_GAME_BOOST_CONFIG_JSON.replace("'", "''")
                await session.execute(text(
                    f"ALTER TABLE admin_config ADD COLUMN game_boost_config VARCHAR DEFAULT '{esc}'"
                ))
                await session.commit()
                print("Successfully added game_boost_config column.")
            else:
                print("game_boost_config column already exists.")
        except Exception as e:
            await session.rollback()
            print(f"Error updating schema: {e}")
            raise e

if __name__ == "__main__":
    asyncio.run(upgrade())
