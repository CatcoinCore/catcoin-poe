"""CLI entrypoint for stale unverified-user cleanup (`python -m jobs.unverified_user_cleanup`)."""

from __future__ import annotations

import asyncio
import logging

from services.unverified_user_cleanup import run_unverified_cleanup_once

log = logging.getLogger(__name__)


def main() -> None:
    logging.basicConfig(level=logging.INFO)
    n = asyncio.run(run_unverified_cleanup_once())
    print(f"deleted_stale_unverified_users={n}")


if __name__ == "__main__":
    main()
