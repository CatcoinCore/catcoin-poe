"""One-shot: drop What's New releases with version < 1.8.0 from admin_config."""
import asyncio
import json
import logging

from sqlalchemy import text

from database import async_engine
from services.whats_new_prune import (
    DEFAULT_WHATS_NEW_MIN_VERSION,
    prune_whats_new_below,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def upgrade() -> None:
    async with async_engine.begin() as conn:
        res = await conn.execute(
            text("SELECT whats_new_json::text FROM admin_config WHERE id = 1")
        )
        row = res.first()
        if not row or not row[0] or row[0].strip() in ("", "null"):
            logger.info("whats_new_json empty; nothing to prune")
            return
        blob = row[0].strip()
        data = json.loads(blob)
        trimmed = prune_whats_new_below(data, DEFAULT_WHATS_NEW_MIN_VERSION)
        if len(trimmed) >= len(data):
            logger.info(
                "whats_new_json already has no releases below %s",
                DEFAULT_WHATS_NEW_MIN_VERSION,
            )
            return
        await conn.execute(
            text(
                "UPDATE admin_config SET whats_new_json = CAST(:b AS JSONB) WHERE id = 1"
            ),
            {"b": json.dumps(trimmed)},
        )
        logger.info("Pruned whats_new_json %s -> %s entries", len(data), len(trimmed))


if __name__ == "__main__":
    asyncio.run(upgrade())
