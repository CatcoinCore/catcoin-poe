import asyncio
from config import settings
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def check_connection():
    url = settings.DATABASE_URL.replace("localhost", "127.0.0.1:5433")
    print(f"Testing URL: {url.split('@')[1] if '@' in url else 'INVALID'}")
    
    engine = create_async_engine(url)
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        print("Connection successful!")
    except Exception as e:
        print(f"Connection failed: {e}")

if __name__ == "__main__":
    asyncio.run(check_connection())
