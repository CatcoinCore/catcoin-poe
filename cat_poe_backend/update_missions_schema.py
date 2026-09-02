import asyncio
import os
from sqlalchemy import text


from database import AsyncSessionLocal, async_engine
import models

async def update_schema():
    try:
        async with AsyncSessionLocal() as db:
            print("Updating database schema...")
            
            # 1. Add columns to missions table
            columns = [
                "title VARCHAR",
                "description VARCHAR",
                "link VARCHAR",
                "icon VARCHAR",
                "is_active BOOLEAN DEFAULT TRUE"
            ]
            
            for col in columns:
                try:
                    await db.execute(text(f"ALTER TABLE missions ADD COLUMN {col}"))
                    await db.commit()
                    print(f"Added column: {col}")
                except Exception as e:
                    await db.rollback()
                    print(f"Column likely exists ({col}): {e}")
                
            # 2. Create user_missions table
            try:
                await db.execute(text("""
                    CREATE TABLE IF NOT EXISTS user_missions (
                        id UUID PRIMARY KEY,
                        user_id UUID NOT NULL REFERENCES users(id),
                        mission_id UUID NOT NULL REFERENCES missions(id),
                        completed_at TIMESTAMP DEFAULT NOW(),
                        status VARCHAR DEFAULT 'COMPLETED', -- PENDING, COMPLETED, REJECTED
                        CONSTRAINT _user_mission_uc UNIQUE (user_id, mission_id)
                    )
                """))
                await db.commit()
                print("Created user_missions table.")
            except Exception as e:
                await db.rollback()
                print(f"Error creating user_missions table: {e}")

            # Add status column if table already exists (idempotency)
            try:
                await db.execute(text("ALTER TABLE user_missions ADD COLUMN status VARCHAR DEFAULT 'COMPLETED'"))
                await db.commit()
                print("Added status column to user_missions.")
            except Exception:
                await db.rollback()
                
            # Seeding is handled by seed_missions.py — see run_all_migrations.py.
            await db.commit()
            print("Schema update complete.")
    finally:
        await async_engine.dispose()

if __name__ == "__main__":
    asyncio.run(update_schema())
