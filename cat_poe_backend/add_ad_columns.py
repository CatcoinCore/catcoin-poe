import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from config import settings

async def add_ad_columns():
    print("Adding ad unit ID columns to admin_config table...")
    
    # Create engine
    engine = create_async_engine(settings.DATABASE_URL)
    
    async with engine.begin() as conn:
        # Add android_ad_unit_id
        try:
            await conn.execute(text("ALTER TABLE admin_config ADD COLUMN android_ad_unit_id VARCHAR"))
            print("Added android_ad_unit_id column.")
        except Exception as e:
            print(f"android_ad_unit_id column might already exist: {e}")

        # Add ios_ad_unit_id
        try:
            await conn.execute(text("ALTER TABLE admin_config ADD COLUMN ios_ad_unit_id VARCHAR"))
            print("Added ios_ad_unit_id column.")
        except Exception as e:
            print(f"ios_ad_unit_id column might already exist: {e}")

    await engine.dispose()
    print("Done.")

if __name__ == "__main__":
    asyncio.run(add_ad_columns())
