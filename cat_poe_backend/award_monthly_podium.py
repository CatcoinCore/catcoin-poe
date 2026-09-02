"""
Grant monthly podium UserBadges: global (top 3), regional per country (top 3 each),
and per game type (top 3 each).

Defaults to the last completed UTC month, or pass --year and --month.

Cron (1st of month, UTC):
  cd /path/cat_poe_backend && python award_monthly_podium.py
"""
from __future__ import annotations

import argparse
import asyncio
import sys

from database import AsyncSessionLocal
from services.monthly_podium_awards import award_all_monthly_podiums, previous_completed_month_bounds


async def main() -> int:
    parser = argparse.ArgumentParser(description="Award monthly podium badges (global + regional + games).")
    parser.add_argument("--year", type=int, default=None)
    parser.add_argument("--month", type=int, default=None)
    args = parser.parse_args()

    if (args.year is None) ^ (args.month is None):
        print("error: specify both --year and --month, or neither", file=sys.stderr)
        return 2
    if args.month is not None and not (1 <= args.month <= 12):
        print("error: --month must be 1-12", file=sys.stderr)
        return 2

    async with AsyncSessionLocal() as db:
        stats = await award_all_monthly_podiums(db, year=args.year, month=args.month)

    if args.year is None:
        b = previous_completed_month_bounds()
        print(f"Period: {b.year}-{b.month:02d} (previous completed UTC month)")
    else:
        print(f"Period: {stats['period_year']}-{stats['period_month']:02d}")

    print(
        f"Global:    +{len(stats['global_awarded'])} new, {len(stats['global_skipped'])} skipped (already had)"
    )
    print(
        f"Regional:  +{stats['regional_awarded_count']} new, {stats['regional_skipped_count']} skipped"
    )
    print(f"Games:     +{stats['game_awarded_count']} new, {stats['game_skipped_count']} skipped")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
