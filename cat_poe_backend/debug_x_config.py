import asyncio
import os
import sys

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

import models
import script_env  # noqa: F401
from services.secret_crypto import decrypt_if_encrypted


def _database_url() -> str:
    url = os.getenv("DATABASE_URL", "").strip()
    if not url:
        print("DATABASE_URL is required (see .env.example).", file=sys.stderr)
        sys.exit(1)
    return url


async def main():
    engine = create_async_engine(_database_url(), echo=False)
    async_session = sessionmaker(
        bind=engine, class_=AsyncSession, expire_on_commit=False
    )

    async with async_session() as db:
        result = await db.execute(
            select(models.AdminConfig).order_by(models.AdminConfig.id.desc())
        )
        config = result.scalars().first()

        if not config:
            print("No AdminConfig found!")
            return

        bearer = decrypt_if_encrypted(config.x_bearer_token)
        masked_bearer = (
            f"{bearer[:5]}…({len(bearer)} chars)" if bearer else None
        )
        print(f"X_COMMUNITY_USERNAME: '{config.x_community_username}'")
        print(f"X_BEARER_TOKEN: '{masked_bearer}'")

        if config.x_community_username and config.x_community_username.strip().isdigit():
            print(
                "WARN: X_COMMUNITY_USERNAME is numeric (Community ID). "
                "Verification will likely AUTO-PASS."
            )
        elif not bearer:
            print(
                "WARN: X_BEARER_TOKEN is missing. Verification might AUTO-PASS (Soft Fail)."
            )
        else:
            print("Config looks OK for Follow verification.")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
