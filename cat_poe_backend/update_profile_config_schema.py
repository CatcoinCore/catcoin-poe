
import asyncio
import os
import sys
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from dotenv import load_dotenv

# Add the parent directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Load environment variables
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

async def update_schema():
    if not DATABASE_URL:
        print("Error: DATABASE_URL not set")
        return

    print(f"Connecting to database...")
    engine = create_async_engine(DATABASE_URL)

    async with engine.begin() as conn:
        print("Checking for enable_profile_picture column in admin_config...")
        
        # Check if column exists
        result = await conn.execute(text(
            "SELECT column_name FROM information_schema.columns "
            "WHERE table_name='admin_config' AND column_name='enable_profile_picture'"
        ))
        
        if result.rowcount == 0:
            print("Adding enable_profile_picture column...")
            await conn.execute(text(
                "ALTER TABLE admin_config ADD COLUMN enable_profile_picture BOOLEAN DEFAULT FALSE"
            ))
            print("Column added successfully.")
        else:
            print("Column 'enable_profile_picture' already exists.")

    await engine.dispose()

if __name__ == "__main__":
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(update_schema())
