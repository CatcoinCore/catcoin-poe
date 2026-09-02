import asyncio
from sqlalchemy.future import select
from database import AsyncSessionLocal
import models

async def fix_admin_config():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(models.AdminConfig).where(models.AdminConfig.id == 1))
        config = result.scalars().first()
        if config and config.coingecko_coin_id == "catcoins":
            config.coingecko_coin_id = "catcoin"
            await db.commit()
            print("Successfully updated coingecko_coin_id to 'catcoin'")
        else:
            print(f"No update needed. Current value: {config.coingecko_coin_id if config else 'None'}")

if __name__ == "__main__":
    asyncio.run(fix_admin_config())
