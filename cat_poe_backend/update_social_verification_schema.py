import asyncio
import os
from sqlalchemy import text
from database import AsyncSessionLocal, async_engine
import models

async def update_schema():
    try:
        async with AsyncSessionLocal() as db:
            print("Updating database schema for Social ID Verification...")
            
            # Add columns to users table
            columns = [
                "discord_id_verified BOOLEAN DEFAULT FALSE",
                "discord_id_old VARCHAR",
                
                "telegram_id_verified BOOLEAN DEFAULT FALSE",
                "telegram_id_old VARCHAR",
                
                "x_id_verified BOOLEAN DEFAULT FALSE",
                "x_id_old VARCHAR",
                
                "facebook_id_verified BOOLEAN DEFAULT FALSE",
                "facebook_id_old VARCHAR",
                
                "whatsapp_id_verified BOOLEAN DEFAULT FALSE",
                "whatsapp_id_old VARCHAR",
            ]
            
            for col in columns:
                try:
                    # Extract column name for logging
                    col_name = col.split()[0]
                    await db.execute(text(f"ALTER TABLE users ADD COLUMN {col}"))
                    await db.commit()
                    print(f"Added column: {col_name}")
                except Exception as e:
                    await db.rollback()
                    print(f"Column likely exists or error ({col}): {str(e)}")
                
            print("Schema update complete.")
    finally:
        await async_engine.dispose()

if __name__ == "__main__":
    asyncio.run(update_schema())
