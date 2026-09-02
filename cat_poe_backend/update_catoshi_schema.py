import asyncio
import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable is not set")

async def update_schema():
    print("Starting schema update for Dynamic Catoshi rewards...")
    engine = create_async_engine(DATABASE_URL)
    
    async with engine.begin() as conn:
        # Add columns to mining_sessions
        try:
            print("Adding reward_y to mining_sessions...")
            await conn.execute(text("ALTER TABLE mining_sessions ADD COLUMN reward_y INTEGER DEFAULT 0"))
        except Exception as e:
            print(f"Column reward_y might already exist: {e}")

        try:
            print("Adding reward_t to mining_sessions...")
            await conn.execute(text("ALTER TABLE mining_sessions ADD COLUMN reward_t INTEGER DEFAULT 1"))
        except Exception as e:
            print(f"Column reward_t might already exist: {e}")

        # Add columns to admin_config
        try:
            print("Adding use_manual_cat_price to admin_config...")
            await conn.execute(text("ALTER TABLE admin_config ADD COLUMN use_manual_cat_price BOOLEAN DEFAULT FALSE"))
        except Exception as e:
            print(f"Column use_manual_cat_price might already exist: {e}")

        try:
            print("Adding manual_cat_price_usdt to admin_config...")
            await conn.execute(text("ALTER TABLE admin_config ADD COLUMN manual_cat_price_usdt INTEGER DEFAULT 50000"))
        except Exception as e:
            print(f"Column manual_cat_price_usdt might already exist: {e}")
            
        try:
            print("Adding coingecko_coin_id to admin_config...")
            await conn.execute(text("ALTER TABLE admin_config ADD COLUMN coingecko_coin_id VARCHAR DEFAULT 'catcoins'"))
        except Exception as e:
            print(f"Column coingecko_coin_id might already exist: {e}")

        try:
            print("Adding catoshi_yield_percentage to admin_config...")
            await conn.execute(text("ALTER TABLE admin_config ADD COLUMN catoshi_yield_percentage FLOAT DEFAULT 100.0"))
        except Exception as e:
            print(f"Column catoshi_yield_percentage might already exist: {e}")

        try:
            print("Adding referral_boost_percentage to admin_config...")
            await conn.execute(text("ALTER TABLE admin_config ADD COLUMN referral_boost_percentage FLOAT DEFAULT 10.0"))
        except Exception as e:
            print(f"Column referral_boost_percentage might already exist: {e}")

        try:
            print("Adding max_active_referrers to admin_config...")
            await conn.execute(text("ALTER TABLE admin_config ADD COLUMN max_active_referrers INTEGER DEFAULT 10"))
        except Exception as e:
            print(f"Column max_active_referrers might already exist: {e}")

    print("Schema update completed successfully.")
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(update_schema())
