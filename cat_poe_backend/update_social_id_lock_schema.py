import asyncio
from sqlalchemy import text
from database import AsyncSessionLocal, async_engine


async def update_schema():
    try:
        async with AsyncSessionLocal() as db:
            print("Adding social ID lock columns and audit table...")

            lock_columns = [
                "discord_id_locked BOOLEAN DEFAULT FALSE",
                "telegram_id_locked BOOLEAN DEFAULT FALSE",
                "x_id_locked BOOLEAN DEFAULT FALSE",
                "facebook_id_locked BOOLEAN DEFAULT FALSE",
                "whatsapp_id_locked BOOLEAN DEFAULT FALSE",
            ]
            for col in lock_columns:
                col_name = col.split()[0]
                try:
                    await db.execute(text(f"ALTER TABLE users ADD COLUMN {col}"))
                    await db.commit()
                    print(f"Added column: {col_name}")
                except Exception as e:
                    await db.rollback()
                    print(f"Column likely exists ({col_name}): {e}")

            try:
                await db.execute(
                    text(
                        """
                        CREATE TABLE IF NOT EXISTS social_verification_audit (
                            id UUID PRIMARY KEY,
                            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                            action VARCHAR(64) NOT NULL,
                            platform VARCHAR(32),
                            detail VARCHAR(1000),
                            amount DOUBLE PRECISION,
                            created_at TIMESTAMP DEFAULT NOW()
                        )
                        """
                    )
                )
                await db.execute(
                    text(
                        "CREATE INDEX IF NOT EXISTS idx_social_verification_audit_user "
                        "ON social_verification_audit(user_id)"
                    )
                )
                await db.commit()
                print("social_verification_audit table ready.")
            except Exception as e:
                await db.rollback()
                print(f"Audit table (may exist): {e}")

            for platform in (
                "discord",
                "telegram",
                "x",
                "facebook",
                "whatsapp",
            ):
                try:
                    await db.execute(
                        text(
                            f"UPDATE users SET {platform}_id_locked = TRUE "
                            f"WHERE {platform}_id_verified = TRUE"
                        )
                    )
                    await db.commit()
                    print(f"Backfilled {platform}_id_locked for verified users.")
                except Exception as e:
                    await db.rollback()
                    print(f"Backfill {platform}: {e}")

            print("Social ID lock schema update complete.")
    finally:
        await async_engine.dispose()


if __name__ == "__main__":
    asyncio.run(update_schema())
