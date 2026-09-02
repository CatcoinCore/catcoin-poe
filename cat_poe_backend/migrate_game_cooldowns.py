import asyncio
import os
import sys

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

import script_env  # noqa: F401 — loads .env before reading DATABASE_URL


def _database_url() -> str:
    url = os.getenv("DATABASE_URL", "").strip()
    if not url:
        print("DATABASE_URL is required (see .env.example).", file=sys.stderr)
        sys.exit(1)
    return url


async def migrate():
    engine = create_async_engine(_database_url())
    async with engine.begin() as conn:
        print("Checking for game_cooldowns table...")

        await conn.execute(
            text("""
            CREATE TABLE IF NOT EXISTS game_cooldowns (
                id UUID PRIMARY KEY,
                user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                game_type VARCHAR NOT NULL,
                play_count INTEGER DEFAULT 0,
                cooldown_until TIMESTAMP WITHOUT TIME ZONE,
                last_updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                UNIQUE (user_id, game_type)
            );
        """)
        )
        print("game_cooldowns table verified.")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(migrate())
