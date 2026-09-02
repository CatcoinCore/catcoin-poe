import asyncio
from sqlalchemy import text
from database import async_engine

async def migrate():
    print("Migrating: Adding is_resolved to suspicious_activities table")
    async with async_engine.begin() as conn:
        try:
            await conn.execute(text("ALTER TABLE suspicious_activities ADD COLUMN is_resolved BOOLEAN DEFAULT FALSE"))
            print("Successfully added is_resolved column.")
        except Exception as e:
            if "already exists" in str(e) or "Duplicate column" in str(e):
                print("Column is_resolved already exists.")
            else:
                print(f"Error adding is_resolved column: {e}")
                
if __name__ == "__main__":
    asyncio.run(migrate())
