import asyncio
from sqlalchemy import text, inspect
from database import AsyncSessionLocal, async_engine

async def check_schema():
    async with async_engine.connect() as conn:
        print("Checking admin_config table columns...")
        result = await conn.execute(text("SELECT column_name, data_type, table_schema FROM information_schema.columns WHERE table_name = 'admin_config';"))
        columns = result.fetchall()
        print("Columns found:")
        found_x_keys = False
        for col in columns:
            print(f"- {col[0]} ({col[1]}) in schema: {col[2]}")
            if 'x_consumer_key' in col[0]:
                found_x_keys = True
        
        if found_x_keys:
            print("\nSUCCESS: x_consumer_key column FOUND.")
            # Try to select from it
            try:
                print("Attempting SELECT x_consumer_key FROM admin_config...")
                await conn.execute(text("SELECT x_consumer_key FROM admin_config LIMIT 1"))
                print("SELECT successful!")
            except Exception as e:
                print(f"SELECT FAILED: {e}")
        
        if found_x_keys:
            print("\nSUCCESS: x_consumer_key column FOUND.")
        else:
            print("\nFAILURE: x_consumer_key column NOT FOUND.")

if __name__ == "__main__":
    asyncio.run(check_schema())
