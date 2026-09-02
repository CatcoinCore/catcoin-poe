import asyncio
import os
import sys

from sqlalchemy import text
from database import AsyncSessionLocal, async_engine
from dotenv import load_dotenv

# Load env to get DB URL if needed (database.py usually handles it)
load_dotenv()


def _community_id() -> str:
    cid = os.getenv("X_COMMUNITY_ID", "").strip()
    if not cid:
        print("Set X_COMMUNITY_ID to your numeric X community id.", file=sys.stderr)
        sys.exit(1)
    if not cid.isdigit():
        print("X_COMMUNITY_ID must be numeric.", file=sys.stderr)
        sys.exit(1)
    return cid


async def update_x_community():
    print("🚀 Updating X Community Configuration...")

    community_id = _community_id()
    community_url = f"https://x.com/i/communities/{community_id}"
    
    try:
        async with AsyncSessionLocal() as session:
            # 1. Update Admin Config
            # Assuming ID=1 is always the config.
            # But let's check if it exists first.
            result = await session.execute(text("SELECT id FROM admin_config LIMIT 1"))
            config = result.first()
            
            if config:
                print(f"Updating AdminConfig ID {config.id}...")
                await session.execute(text(f"""
                    UPDATE admin_config 
                    SET x_community_username = '{community_id}'
                    WHERE id = {config.id}
                """))
                print("✅ AdminConfig updated with Community ID.")
            else:
                print("AdminConfig not found. Creating default row...")
                await session.execute(text(f"""
                    INSERT INTO admin_config (id, x_community_username) 
                    VALUES (1, '{community_id}')
                """))
                print("✅ AdminConfig created with Community ID.")

            # 2. Update Mission Link & Description
            print("Updating Mission 'FOLLOW_X'...")
            await session.execute(text(f"""
                UPDATE missions 
                SET link = '{community_url}',
                    title = 'Join X Community',
                    description = 'Join our official X Community for latest updates.'
                WHERE code = 'FOLLOW_X'
            """))
            
            await session.commit()
            print("✅ Mission 'FOLLOW_X' updated successfully.")
    finally:
        await async_engine.dispose()

if __name__ == "__main__":
    if os.name == 'nt':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(update_x_community())
