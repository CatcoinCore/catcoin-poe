"""Replace admin_config.whats_new_json with seed_data/default_whats_new.json (id=1).

Run from cat_poe_backend with DATABASE_URL / same env as the API:
    python force_import_whats_new_seed.py
"""
import asyncio
import json
import sys
from pathlib import Path

from sqlalchemy import text

from database import async_engine
from schemas import _validate_whats_new_json


async def main() -> int:
    root = Path(__file__).resolve().parent
    seed_path = root / "seed_data" / "default_whats_new.json"
    try:
        raw = seed_path.read_text(encoding="utf-8").strip()
    except OSError as exc:
        print(f"ERROR: cannot read {seed_path}: {exc}", file=sys.stderr)
        return 2

    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError as exc:
        print(f"ERROR: {seed_path} is not valid JSON: {exc}", file=sys.stderr)
        return 2

    # Same shape rules as PUT /admin/config; surfaces precise field errors here
    # rather than at the next admin save.
    try:
        cleaned = _validate_whats_new_json(parsed)
    except ValueError as exc:
        print(f"ERROR: seed failed validation: {exc}", file=sys.stderr)
        return 2

    blob = json.dumps(cleaned)
    async with async_engine.begin() as conn:
        result = await conn.execute(
            text(
                "UPDATE admin_config SET whats_new_json = CAST(:b AS JSONB) "
                "WHERE id = 1"
            ),
            {"b": blob},
        )
        rows = result.rowcount if result.rowcount is not None else -1

    if rows == 0:
        print(
            "WARNING: no admin_config row with id=1 was updated. "
            "Create the singleton row first.",
            file=sys.stderr,
        )
        return 1
    print(f"Imported whats_new_json from {seed_path.name} ({len(cleaned)} releases, {rows} row updated).")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
