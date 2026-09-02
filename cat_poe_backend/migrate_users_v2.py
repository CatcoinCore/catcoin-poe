import asyncio
from sqlalchemy import text
from database import async_engine

async def migrate():
    print("Starting migration for users table...")
    async with async_engine.begin() as conn:
        try:
            # Check total_earnings
            res = await conn.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='total_earnings'"))
            if not res.first():
                print("Adding total_earnings to users...")
                await conn.execute(text("ALTER TABLE users ADD COLUMN total_earnings FLOAT DEFAULT 0.0"))
            else:
                print("total_earnings already exists.")

            # Check country_source
            res = await conn.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='country_source'"))
            if not res.first():
                print("Adding country_source to users...")
                await conn.execute(text("ALTER TABLE users ADD COLUMN country_source VARCHAR(10)"))
            else:
                print("country_source already exists.")

            print("Migration completed successfully.")
        except Exception as e:
            print(f"Migration error: {e}")

if __name__ == "__main__":
    asyncio.run(migrate())
