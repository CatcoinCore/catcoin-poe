"""
Remove email-unverified accounts past a retention window so emails can be reused.

Signup-only users rarely have child rows, but FK constraints vary; we delete dependents
in a safe order then remove the user row.
"""

from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Sequence
from uuid import UUID

from sqlalchemy import delete, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession

import models
from config import settings

log = logging.getLogger(__name__)


def _retention_cutoff() -> datetime:
    hours = max(1, int(settings.UNVERIFIED_USER_RETENTION_HOURS))
    return datetime.utcnow() - timedelta(hours=hours)


async def select_stale_unverified_user_ids(db: AsyncSession) -> Sequence[UUID]:
    cutoff = _retention_cutoff()
    q = await db.execute(
        select(models.User.id).where(
            models.User.email_verified.is_(False),
            models.User.is_admin.is_(False),
            models.User.balance == 0.0,
            models.User.total_earnings == 0.0,
            models.User.created_at < cutoff,
        )
    )
    return [row[0] for row in q.all()]


async def _purge_dependencies_for_users(db: AsyncSession, user_ids: list[UUID]) -> None:
    if not user_ids:
        return

    referral_scope = select(models.Referral.id).where(
        or_(
            models.Referral.referee_user_id.in_(user_ids),
            models.Referral.referrer_user_id.in_(user_ids),
        )
    )

    await db.execute(
        delete(models.EarningsLedger).where(
            or_(
                models.EarningsLedger.user_id.in_(user_ids),
                models.EarningsLedger.referral_id.in_(referral_scope),
            )
        )
    )

    mining_sessions_for_users = select(models.MiningSession.id).where(
        models.MiningSession.user_id.in_(user_ids)
    )
    await db.execute(
        delete(models.LedgerSessionMapping).where(
            models.LedgerSessionMapping.session_id.in_(mining_sessions_for_users)
        )
    )

    await db.execute(
        update(models.MiningSession)
        .where(models.MiningSession.user_id.in_(user_ids))
        .values(ledger_entry_id=None)
    )

    await db.execute(
        delete(models.UserGameBoost).where(models.UserGameBoost.user_id.in_(user_ids))
    )

    await db.execute(
        update(models.MiningSession)
        .where(models.MiningSession.mining_for.in_(user_ids))
        .values(mining_for=None)
    )

    await db.execute(
        delete(models.MiningSession).where(models.MiningSession.user_id.in_(user_ids))
    )

    await db.execute(delete(models.Payout).where(models.Payout.user_id.in_(user_ids)))

    await db.execute(
        delete(models.GameReward).where(models.GameReward.user_id.in_(user_ids))
    )

    await db.execute(
        delete(models.GameSession).where(models.GameSession.user_id.in_(user_ids))
    )

    await db.execute(delete(models.AdView).where(models.AdView.user_id.in_(user_ids)))

    await db.execute(
        delete(models.UserMission).where(models.UserMission.user_id.in_(user_ids))
    )

    await db.execute(delete(models.Wallet).where(models.Wallet.user_id.in_(user_ids)))

    await db.execute(
        delete(models.SuspiciousActivity).where(
            models.SuspiciousActivity.user_id.in_(user_ids)
        )
    )
    await db.execute(
        update(models.SuspiciousActivity)
        .where(models.SuspiciousActivity.related_user_id.in_(user_ids))
        .values(related_user_id=None)
    )

    await db.execute(
        update(models.SpecialBonusCode)
        .where(models.SpecialBonusCode.used_by.in_(user_ids))
        .values(used_by=None)
    )

    await db.execute(
        update(models.Referral)
        .where(models.Referral.bonus_reviewed_by.in_(user_ids))
        .values(bonus_reviewed_by=None)
    )


async def delete_stale_unverified_users(db: AsyncSession) -> int:
    """
    Delete unverified non-admin users with zero earnings older than the retention window.

    Returns the number of users deleted.
    """
    ids = list(await select_stale_unverified_user_ids(db))
    if not ids:
        return 0

    try:
        await _purge_dependencies_for_users(db, ids)

        r = await db.execute(delete(models.User).where(models.User.id.in_(ids)))
        await db.commit()

        n = r.rowcount if r.rowcount is not None and r.rowcount >= 0 else len(ids)
        log.info(
            "Stale unverified user cleanup removed %s account(s) (retention=%sh)",
            n,
            settings.UNVERIFIED_USER_RETENTION_HOURS,
        )
        return n
    except Exception:
        await db.rollback()
        raise


async def run_unverified_cleanup_periodically() -> None:
    """Optional in-process loop (started from FastAPI startup)."""
    await asyncio.sleep(120)
    while True:
        try:
            from database import AsyncSessionLocal

            async with AsyncSessionLocal() as db:
                await delete_stale_unverified_users(db)
        except Exception:
            log.exception("Stale unverified user cleanup error")
        await asyncio.sleep(settings.UNVERIFIED_CLEANUP_INTERVAL_SECONDS)


async def run_unverified_cleanup_once() -> int:
    """Single pass for cron / `python -m jobs.unverified_user_cleanup`."""
    from database import AsyncSessionLocal

    async with AsyncSessionLocal() as db:
        return await delete_stale_unverified_users(db)
