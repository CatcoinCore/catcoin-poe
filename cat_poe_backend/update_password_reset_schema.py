"""users.password_reset_* + refresh_tokens.family_id (Alembic auth_hardening_001); idempotent for DBs that never ran that revision."""

import asyncio
from sqlalchemy import text

from database import async_engine


async def migrate() -> None:
    print("Ensuring password reset columns and refresh_tokens.family_id...")
    async with async_engine.begin() as conn:
        await conn.execute(
            text(
                "ALTER TABLE public.users ADD COLUMN IF NOT EXISTS password_reset_code VARCHAR(6)"
            )
        )
        await conn.execute(
            text(
                "ALTER TABLE public.users ADD COLUMN IF NOT EXISTS password_reset_expires TIMESTAMP"
            )
        )

        await conn.execute(
            text(
                "ALTER TABLE public.refresh_tokens ADD COLUMN IF NOT EXISTS family_id UUID"
            )
        )
        await conn.execute(
            text(
                "UPDATE public.refresh_tokens SET family_id = id WHERE family_id IS NULL"
            )
        )
        await conn.execute(
            text(
                "ALTER TABLE public.refresh_tokens ALTER COLUMN family_id SET NOT NULL"
            )
        )
        await conn.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_refresh_tokens_family_id "
                "ON public.refresh_tokens (family_id)"
            )
        )
    print("Done.")


if __name__ == "__main__":
    asyncio.run(migrate())
