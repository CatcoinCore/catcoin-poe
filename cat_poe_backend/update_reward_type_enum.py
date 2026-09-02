import asyncio
from sqlalchemy import text
from database import AsyncSessionLocal

async def upgrade():
    async with AsyncSessionLocal() as session:
        try:
            # Check database dialect
            # For Postgres, we need ALTER TYPE
            # For SQLite (testing/local), we might not need to do anything or it might not support it
            # Catcoin uses Postgres in production.
            
            print("Adding SPECIAL_BONUS to RewardType enum...")
            # We wrap in a block that catches error if the value already exists
            await session.execute(text("ALTER TYPE rewardtype ADD VALUE 'SPECIAL_BONUS'"))
            await session.commit()
            print("Successfully added SPECIAL_BONUS to RewardType enum.")
        except Exception as e:
            await session.rollback()
            if "already exists" in str(e):
                print("SPECIAL_BONUS already exists in RewardType enum.")
            else:
                print(f"Error updating enum: {e}")
                # We don't raise here to allow it to be idempotent on SQLite/non-Postgres environments if applicable
                # but in production, we want it to work.

async def run_migration():
    await upgrade()

if __name__ == "__main__":
    asyncio.run(run_migration())
