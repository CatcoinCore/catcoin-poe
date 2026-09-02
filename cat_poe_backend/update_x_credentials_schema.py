import asyncio
from sqlalchemy import text
from database import AsyncSessionLocal, async_engine

async def update_schema():
    try:
        async with AsyncSessionLocal() as db:
            print("Updating database schema for X Credentials...")
            
            columns = [
                "x_bearer_token VARCHAR",
                "x_community_username VARCHAR",
                "enable_verification_release BOOLEAN DEFAULT TRUE",
                "enable_verification_debug BOOLEAN DEFAULT TRUE",
                "coin_explorer_api_key VARCHAR",
                "enable_wallet_holding_days BOOLEAN DEFAULT TRUE",
                "latest_version_android VARCHAR DEFAULT '1.0.0'",
                "min_version_android VARCHAR DEFAULT '1.0.0'",
                "update_url_android VARCHAR DEFAULT 'https://play.google.com/store/apps/details?id=org.catcoin.cat'",
                "latest_version_ios VARCHAR DEFAULT '1.0.0'",
                "min_version_ios VARCHAR DEFAULT '1.0.0'",
                "update_url_ios VARCHAR DEFAULT 'https://apps.apple.com/app/id123456789'",
                "latest_version_windows VARCHAR DEFAULT '1.0.0'",
                "min_version_windows VARCHAR DEFAULT '1.0.0'",
                "update_url_windows VARCHAR DEFAULT 'https://catcoin.in/download'",
                "x_consumer_key VARCHAR",
                "x_consumer_secret VARCHAR",
                "x_access_token VARCHAR",
                "x_access_token_secret VARCHAR",
                "x_client_id VARCHAR",
                "x_client_secret VARCHAR",
                "verification_backoff_delays VARCHAR DEFAULT '[120, 180, 300, 420, 600]'"
            ]
            
            for col_def in columns:
                try:
                    col_name = col_def.split()[0]
                    # Check if column exists first to avoid transaction aborts
                    # Note: valid only for postgres
                    check_query = text(f"SELECT column_name FROM information_schema.columns WHERE table_name='admin_config' AND column_name='{col_name}'")
                    result = await db.execute(check_query)
                    if result.scalar():
                        print(f"Skipping {col_name} (already exists)")
                        continue

                    await db.execute(text(f"ALTER TABLE admin_config ADD COLUMN {col_def}"))
                    await db.commit()
                    print(f"Added column: {col_name}")
                except Exception as e:
                    await db.rollback()
                    # Allow failure if column exists or other error, but log it
                    print(f"Failed to add {col_name}: {e}")
            print("Schema update complete.")
    finally:
        await async_engine.dispose()

if __name__ == "__main__":
    asyncio.run(update_schema())
