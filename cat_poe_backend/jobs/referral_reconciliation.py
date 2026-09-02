"""Periodic reconciliation and CLI entrypoint for referral milestone bonuses."""

from __future__ import annotations

import asyncio
import logging

from database import AsyncSessionLocal
from services.referral_bonus import run_referral_bonus_reconciliation

log = logging.getLogger(__name__)


async def run_referral_reconciliation_periodically() -> None:
    """In-process daily loop (optional; advisory lock prevents duplicate work)."""
    await asyncio.sleep(300)
    while True:
        try:
            async with AsyncSessionLocal() as db:
                # Summary line: referral_milestone reconciliation_run / reconciliation_skipped_lock
                await run_referral_bonus_reconciliation(db)
        except Exception:
            log.exception("Referral reconciliation error")
        await asyncio.sleep(86400)


async def run_once() -> int:
    """Single scan (cron / APScheduler / `python -m jobs.referral_reconciliation`)."""
    async with AsyncSessionLocal() as db:
        return await run_referral_bonus_reconciliation(db)


def main() -> None:
    logging.basicConfig(level=logging.INFO)
    n = asyncio.run(run_once())
    print(f"referral_reconciliation_processed={n}")


if __name__ == "__main__":
    main()
