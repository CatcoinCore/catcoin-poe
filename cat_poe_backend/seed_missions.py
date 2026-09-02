import asyncio
import os
from sqlalchemy import text


from database import AsyncSessionLocal, async_engine
import models
import uuid

async def seed_missions():
    try:
        async with AsyncSessionLocal() as db:
            print("Seeding missions...")
            missions_data = [
                {
                    "code": "JOIN_DISCORD",
                    "title": "Join Discord Community",
                    "description": "Join our official Discord server to stay updated.",
                    "link": "https://discord.gg/YOUR_INVITE_CODE",
                    "icon": "discord",
                    "type": "SOCIAL",
                    "reward_amount": 100000
                },
                {
                    "code": "FOLLOW_X",
                    "title": "Follow @catcoin",
                    "description": "Follow our official X account @catcoin for latest news.",
                    "link": "https://x.com/i/communities/YOUR_COMMUNITY_ID",
                    "icon": "twitter",
                    "type": "SOCIAL",
                    "reward_amount": 100000
                },
                {
                    "code": "JOIN_TELEGRAM",
                    "title": "Join Telegram Channel",
                    "description": "Subscribe to our Telegram channel.",
                    "link": "https://t.me/YOUR_TELEGRAM_CHANNEL",
                    "icon": "telegram",
                    "type": "SOCIAL",
                    "reward_amount": 100000
                }
            ]
            
            for m_data in missions_data:
                # Check if exists
                result = await db.execute(text(f"SELECT id FROM missions WHERE code = '{m_data['code']}'"))
                existing = result.first()
                
                if existing:
                    print(f"Mission already exists: {m_data['code']}")
                    # Only update metadata — do NOT touch reward_amount.
                    # Admins set rewards via the admin panel and that value must persist across deploys.
                    await db.execute(text(f"UPDATE missions SET link = '{m_data['link']}', title = '{m_data['title']}' WHERE code = '{m_data['code']}'"))
                else:
                    # Insert
                    await db.execute(text(f"""
                        INSERT INTO missions (id, code, title, description, link, icon, type, reward_amount, is_active)
                        VALUES ('{uuid.uuid4()}', '{m_data['code']}', '{m_data['title']}', '{m_data['description']}', '{m_data['link']}', '{m_data['icon']}', '{m_data['type']}', {m_data['reward_amount']}, TRUE)
                    """))
                    print(f"Created mission: {m_data['code']}")
            
            await db.commit()
            print("Seeding complete.")
    except Exception as e:
        print(f"Error seeding missions: {e}")
        raise e

async def main():
    try:
        await seed_missions()
    finally:
        # Explicitly dispose of engine to prevent hang when run standalone
        from database import async_engine
        await async_engine.dispose()

if __name__ == "__main__":
    asyncio.run(main())
