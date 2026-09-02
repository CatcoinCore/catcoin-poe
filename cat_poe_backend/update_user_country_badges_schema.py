import asyncio
import os
from sqlalchemy import text

from database import AsyncSessionLocal, async_engine

async def update_schema():
    try:
        async with AsyncSessionLocal() as db:
            print("Updating User Country and Badges schema...")
            
            # 1. Add country column to users table
            try:
                await db.execute(text("ALTER TABLE users ADD COLUMN country VARCHAR(2) DEFAULT 'US'"))
                await db.commit()
                print("Added country column to users.")
            except Exception as e:
                await db.rollback()
                print(f"Column 'country' likely exists on users: {e}")
                
            # 2. Create user_badges table
            try:
                await db.execute(text("""
                    CREATE TABLE IF NOT EXISTS user_badges (
                        id UUID PRIMARY KEY,
                        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                        badge_type VARCHAR NOT NULL,
                        description VARCHAR,
                        awarded_at TIMESTAMP DEFAULT NOW()
                    )
                """))
                await db.commit()
                print("Created user_badges table.")
            except Exception as e:
                await db.rollback()
                print(f"Error creating user_badges table: {e}")

            # 3. Create Index for user_badges
            try:
                await db.execute(text("""
                    CREATE INDEX IF NOT EXISTS idx_user_badges ON user_badges (user_id);
                """))
                await db.commit()
                print("Created index idx_user_badges.")
            except Exception as e:
                await db.rollback()
                print(f"Error creating index idx_user_badges: {e}")

            print("Schema update complete.")
    finally:
        await async_engine.dispose()

if __name__ == "__main__":
    asyncio.run(update_schema())
