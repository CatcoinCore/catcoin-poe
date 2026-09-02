import asyncio
from sqlalchemy import text
from database import AsyncSessionLocal

async def run_query():
    try:
        async with AsyncSessionLocal() as db:
            print("Attempting to SELECT use_manual_cat_price FROM admin_config...")
            result = await db.execute(text('SELECT use_manual_cat_price FROM admin_config'))
            rows = result.fetchall()
            print(f"Success! {len(rows)} rows found.")
            for row in rows:
                print(row)
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(run_query())
