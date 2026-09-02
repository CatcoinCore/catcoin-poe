import asyncio
from sqlalchemy import text

from admin_config_defaults import DEFAULT_GAME_REWARD_CONFIG_JSON
from database import async_engine as engine


async def run_migration():
    async with engine.begin() as conn:
        print("Adding game_reward_config to admin_config table...")
        try:
            esc = DEFAULT_GAME_REWARD_CONFIG_JSON.replace("'", "''")
            await conn.execute(text(
                f"ALTER TABLE admin_config ADD COLUMN game_reward_config VARCHAR DEFAULT '{esc}'"
            ))
            print("Successfully added game_reward_config column.")
        except Exception as e:
            if "already exists" in str(e):
                print("Column game_reward_config already exists.")
            else:
                print(f"Error adding column: {e}")

if __name__ == "__main__":
    asyncio.run(run_migration())
