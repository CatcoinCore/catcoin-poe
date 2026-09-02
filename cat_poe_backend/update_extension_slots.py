import asyncio
from database import AsyncSessionLocal, async_engine
from sqlalchemy import text

async def update_config():
    try:
        async with AsyncSessionLocal() as db:
            await db.execute(
                text("UPDATE admin_config SET time_extension_slots = '[120, 180, 240, 300, 360]' WHERE id = 1")
            )
            await db.commit()
            print("Updated time_extension_slots successfully!")
    finally:
        await async_engine.dispose()

if __name__ == "__main__":
    asyncio.run(update_config())
