import asyncio
from sqlalchemy import text
from database import async_engine

async def migrate():
    """Ensure admin_config.app_ads_content exists (matches ORM / main.py startup)."""
    print("Running Migration: Ensuring public.admin_config.app_ads_content exists...")

    async with async_engine.begin() as conn:
        await conn.execute(
            text(
                "ALTER TABLE public.admin_config "
                "ADD COLUMN IF NOT EXISTS app_ads_content TEXT"
            )
        )

        user_content = """greenadexchange.com, 12345, DIRECT, d75815a79

silverssp.com, 9675, RESELLER, 496211

blueadexchange.com, XF436, DIRECT

orangeexchange.com, 45678, RESELLER

silverssp.com, ABE679, RESELLER

google.com, pub-0000000000000000, DIRECT"""

        await conn.execute(
            text(
                "UPDATE public.admin_config SET app_ads_content = :content "
                "WHERE app_ads_content IS NULL OR app_ads_content = ''"
            ),
            {"content": user_content},
        )
    print("Successfully ensured app_ads_content on admin_config.")


if __name__ == "__main__":
    asyncio.run(migrate())
