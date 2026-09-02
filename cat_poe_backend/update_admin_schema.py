import asyncio
import os
from sqlalchemy import text
from database import AsyncSessionLocal, async_engine
import models

async def update_schema():
    try:
        async with AsyncSessionLocal() as db:
            print("Updating database schema for Admin Config...")
            
            # Add columns to admin_config table
            columns = [
                "coin_explorer_api_key VARCHAR",
                "enable_wallet_holding_days BOOLEAN DEFAULT TRUE",
                "enable_verification_release BOOLEAN DEFAULT TRUE",
                "enable_verification_debug BOOLEAN DEFAULT TRUE",
                "x_bearer_token VARCHAR",
                "x_community_username VARCHAR"
            ]
            
            for col in columns:
                try:
                    # Extract column name for logging
                    col_name = col.split()[0]
                    await db.execute(text(f"ALTER TABLE admin_config ADD COLUMN {col}"))
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
