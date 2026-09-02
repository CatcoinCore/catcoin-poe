import asyncio
from sqlalchemy import text
from database import AsyncSessionLocal, async_engine

async def update_schema():
    try:
        async with AsyncSessionLocal() as db:
            print("Updating database schema for Admin Config (Game Visibility)...")
            
            # Add columns to admin_config table
            columns = [
                "is_runner_game_visible BOOLEAN DEFAULT TRUE",
                "is_miner_game_visible BOOLEAN DEFAULT TRUE",
                "is_tictactoe_game_visible BOOLEAN DEFAULT TRUE",
                "is_sudoku_game_visible BOOLEAN DEFAULT TRUE",
                "is_collage_game_visible BOOLEAN DEFAULT TRUE",
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
