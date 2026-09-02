"""
Fill admin_config (singleton id=1) from process environment when DB fields are empty.

Use on first deploy: set Discord / Telegram / X / ad unit / explorer keys in `.env` or
compose `environment`, run migrations — this script copies non-empty env values into
columns that are still NULL or blank.

Set ADMIN_CONFIG_ENV_FORCE=1 (or true) to overwrite DB from env whenever env is non-empty
(e.g. rotate tokens via redeploy).

Run automatically from run_all_migrations.py / apply_db_migrations.sh.
"""

from __future__ import annotations

import asyncio
import os
from typing import Any, Callable, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

import models
from database import AsyncSessionLocal
from services import admin_config_schema_compat as _admin_schema_compat
from services.admin_config_schema_compat import (
    ensure_error_report_email_column,
    ensure_referral_milestone_bonus_catoshi_column,
    ensure_referral_signup_bonus_columns,
)
from services.secret_crypto import encrypt_secret, SENSITIVE_ADMIN_CONFIG_FIELDS
from services.session_manager import SessionManager


async def _ensure_tile_swap_game_visible_column(db: AsyncSession) -> bool:
    """
    Ensure ``is_tile_swap_game_visible`` exists (see admin_config_schema_compat).

    Deployments sometimes ship a newer seed script with an older compat module;
    avoid ImportError by delegating to compat when present, else run the same DDL here.
    """
    fn = getattr(_admin_schema_compat, "ensure_tile_swap_game_visible_column", None)
    if callable(fn):
        return await fn(db)
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


def _is_blank(value: Any) -> bool:
    if value is None:
        return True
    if isinstance(value, str) and not value.strip():
        return True
    return False


# (env_var, AdminConfig attribute)
_STRING_FIELDS: list[tuple[str, str]] = [
    ("DISCORD_BOT_TOKEN", "discord_bot_token"),
    ("DISCORD_GUILD_ID", "discord_guild_id"),
    ("TELEGRAM_BOT_TOKEN", "telegram_bot_token"),
    ("TELEGRAM_CHAT_ID", "telegram_chat_id"),
    ("X_BEARER_TOKEN", "x_bearer_token"),
    ("X_COMMUNITY_USERNAME", "x_community_username"),
    ("X_CONSUMER_KEY", "x_consumer_key"),
    ("X_CONSUMER_SECRET", "x_consumer_secret"),
    ("X_ACCESS_TOKEN", "x_access_token"),
    ("X_ACCESS_TOKEN_SECRET", "x_access_token_secret"),
    ("X_CLIENT_ID", "x_client_id"),
    ("X_CLIENT_SECRET", "x_client_secret"),
    ("ANDROID_AD_UNIT_ID", "android_ad_unit_id"),
    ("IOS_AD_UNIT_ID", "ios_ad_unit_id"),
    ("COIN_EXPLORER_API_KEY", "coin_explorer_api_key"),
    ("COINGECKO_COIN_ID", "coingecko_coin_id"),
    ("ERROR_REPORT_EMAIL", "error_report_email"),
]


async def seed(*, force: Optional[bool] = None) -> None:
    if force is None:
        force = os.getenv("ADMIN_CONFIG_ENV_FORCE", "").strip().lower() in (
            "1",
            "true",
            "yes",
        )

    async with AsyncSessionLocal() as db:
        if await ensure_referral_signup_bonus_columns(db):
            await db.commit()
        if await ensure_referral_milestone_bonus_catoshi_column(db):
            await db.commit()
        if await _ensure_tile_swap_game_visible_column(db):
            await db.commit()
        if await ensure_error_report_email_column(db):
            await db.commit()
        config = await SessionManager.get_admin_config(db)
        updated: list[str] = []

        for env_name, attr in _STRING_FIELDS:
            raw = os.getenv(env_name)
            if raw is None:
                continue
            val = raw.strip()
            if not val:
                continue
            current = getattr(config, attr, None)
            if force or _is_blank(current):
                if attr in SENSITIVE_ADMIN_CONFIG_FIELDS:
                    setattr(config, attr, encrypt_secret(val))
                else:
                    setattr(config, attr, val)
                updated.append(attr)

        if updated:
            await db.commit()
            mode = "force" if force else "fill-empty"
            print(f"admin_config: updated ({mode}): {', '.join(sorted(updated))}")
        else:
            print("admin_config: no env-based updates (already set or env empty).")


if __name__ == "__main__":
    asyncio.run(seed())
