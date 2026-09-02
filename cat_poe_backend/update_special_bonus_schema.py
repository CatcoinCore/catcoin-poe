import asyncio
from sqlalchemy import text
from database import AsyncSessionLocal

async def upgrade():
    async with AsyncSessionLocal() as session:
        try:
            # Create the special_bonus_codes table
            print("Creating special_bonus_codes table...")
            await session.execute(text("""
                CREATE TABLE IF NOT EXISTS special_bonus_codes (
                    id UUID PRIMARY KEY,
                    code VARCHAR(24) UNIQUE NOT NULL,
                    amount FLOAT NOT NULL,
                    is_used BOOLEAN DEFAULT FALSE,
                    used_by UUID REFERENCES users(id),
                    used_at TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """))
            await session.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_special_bonus_code ON special_bonus_codes(code)
            """))
            await session.commit()
            print("Successfully created special_bonus_codes table.")
        except Exception as e:
            await session.rollback()
            print(f"Error updating schema: {e}")
            raise e

if __name__ == "__main__":
    asyncio.run(upgrade())
