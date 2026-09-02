import asyncio
from sqlalchemy import text
from database import async_engine

async def migrate():
    print("🚀 Running Game Boosts Schema Update...")
    
    # 1. Add can_withdraw_game_boosts to users table
    print("Checking for can_withdraw_game_boosts in users...")
    try:
        async with async_engine.begin() as conn:
            await conn.execute(text("ALTER TABLE users ADD COLUMN can_withdraw_game_boosts BOOLEAN DEFAULT FALSE"))
            print("Successfully added can_withdraw_game_boosts column.")
    except Exception as e:
        if "already exists" in str(e).lower():
            print("Note: Column can_withdraw_game_boosts already exists.")
        else:
            print(f"Non-critical error adding column: {e}")

    # 2. Create user_game_boosts table
    print("Creating user_game_boosts table...")
    try:
        async with async_engine.begin() as conn:
            await conn.execute(text("""
                CREATE TABLE IF NOT EXISTS user_game_boosts (
                    id UUID PRIMARY KEY,
                    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                    percentage FLOAT NOT NULL,
                    duration_minutes INTEGER NOT NULL,
                    is_used BOOLEAN DEFAULT FALSE,
                    session_id UUID REFERENCES mining_sessions(id) ON DELETE SET NULL,
                    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """))
            print("Successfully created user_game_boosts table.")
    except Exception as e:
        print(f"Error creating user_game_boosts table: {e}")
        raise # This is critical
    
    # 3. Add index for performance
    print("Adding index for user_id on user_game_boosts...")
    try:
        async with async_engine.begin() as conn:
            await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_user_game_boosts_user ON user_game_boosts(user_id)"))
            print("Successfully created index.")
    except Exception as e:
        print(f"Note: Error adding index (might exist): {e}")

    print("✅ Game Boosts Migration Complete!")

if __name__ == "__main__":
    asyncio.run(migrate())
