import asyncio
from sqlalchemy import text
from database import AsyncSessionLocal

async def update_version():
    async with AsyncSessionLocal() as session:
        # Use a targeted raw SQL query to be resilient against missing columns in the model
        result = await session.execute(text("SELECT latest_version_android FROM admin_config WHERE id = 1"))
        current_version = result.scalar()
        
        if current_version is not None:
            print(f"Current version: {current_version}")
            new_version = "1.12.0"
            await session.execute(
                text("UPDATE admin_config SET latest_version_android = :v, min_version_android = :min_v WHERE id = 1"),
                {"v": new_version, "min_v": "1.10.0"}
            )
            await session.commit()
            print(f"Updated version to: {new_version}")
        else:
            print("AdminConfig row with id=1 not found.")

if __name__ == "__main__":
    asyncio.run(update_version())
