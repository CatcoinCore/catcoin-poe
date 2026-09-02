"""Add admin_config columns when ORM is newer than the database.

Deployments that run ``seed_admin_config_from_env.py`` (or other scripts) without
starting FastAPI never hit ``main.py`` startup auto-migration — keep DDL here in sync
with [models.AdminConfig] and ``main.py`` ``admin_cols`` for new fields.
"""
from __future__ import annotations

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


async def ensure_referral_signup_bonus_columns(db: AsyncSession) -> bool:
    """
    Ensure referral signup bonus amount columns exist on ``admin_config``.

    Returns True if at least one ``ALTER TABLE`` ran (caller may want to ``commit``).
    """
    added = False
    pairs = (
        ("referral_signup_bonus_referee_amount", "FLOAT DEFAULT 100.0"),
        ("referral_signup_bonus_referrer_amount", "FLOAT DEFAULT 50.0"),
    )
    for col_name, col_type in pairs:
        res = await db.execute(
            text(
                "SELECT 1 FROM information_schema.columns "
                "WHERE table_schema = 'public' AND table_name = 'admin_config' "
                "AND column_name = :name"
            ),
            {"name": col_name},
        )
        if res.first() is None:
            await db.execute(
                text(f"ALTER TABLE admin_config ADD COLUMN {col_name} {col_type}")
            )
            added = True
    return added


async def ensure_referral_milestone_bonus_catoshi_column(db: AsyncSession) -> bool:
    """
    Ensure ``referral_milestone_bonus_catoshi`` exists on ``admin_config``.

    Returns True if ``ALTER TABLE`` ran.
    """
    res = await db.execute(
        text(
            "SELECT 1 FROM information_schema.columns "
            "WHERE table_schema = 'public' AND table_name = 'admin_config' "
            "AND column_name = 'referral_milestone_bonus_catoshi'"
        )
    )
    if res.first() is not None:
        return False
    await db.execute(
        text(
            "ALTER TABLE admin_config ADD COLUMN referral_milestone_bonus_catoshi "
            "BIGINT NOT NULL DEFAULT 10000000"
        )
    )
    return True


async def ensure_tile_swap_game_visible_column(db: AsyncSession) -> bool:
    """
    Ensure ``is_tile_swap_game_visible`` exists on ``admin_config``.

    ORM models may ship before migrations run; ``seed_admin_config_from_env`` uses
    ``SessionManager.get_admin_config`` and needs this column in PostgreSQL.

    Defaults to ``TRUE`` — the Tile Swap gameplay ships alongside this shim
    so the toggle should be on by default for fresh deploys. Admins can hide
    the tile from the games tab via ``PUT /admin/config`` if they want to
    A/B it or pull it for a region.

    Returns True if ``ALTER TABLE`` ran.
    """
    res = await db.execute(
        text(
            "SELECT 1 FROM information_schema.columns "
            "WHERE table_schema = 'public' AND table_name = 'admin_config' "
            "AND column_name = 'is_tile_swap_game_visible'"
        )
    )
    if res.first() is not None:
        return False
    await db.execute(
        text(
            "ALTER TABLE admin_config ADD COLUMN is_tile_swap_game_visible "
            "BOOLEAN DEFAULT TRUE"
        )
    )
    return True


async def ensure_error_report_email_column(db: AsyncSession) -> bool:
    """
    Ensure ``error_report_email`` exists on ``admin_config``.

    Nullable string column that receives admin-routed client error reports
    when the ``ERROR_REPORT_EMAIL`` env var is not set. Plaintext (not a
    secret). Returns True if ``ALTER TABLE`` ran.
    """
    res = await db.execute(
        text(
            "SELECT 1 FROM information_schema.columns "
            "WHERE table_schema = 'public' AND table_name = 'admin_config' "
            "AND column_name = 'error_report_email'"
        )
    )
    if res.first() is not None:
        return False
    await db.execute(
        text(
            "ALTER TABLE admin_config ADD COLUMN error_report_email "
            "VARCHAR NULL"
        )
    )
    return True
