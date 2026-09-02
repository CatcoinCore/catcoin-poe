"""Referral milestone bonus: live metrics, snapshot refresh, evaluation, payout."""
from __future__ import annotations

import dataclasses
import logging
from datetime import datetime
from typing import Optional

from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession
import models
from services.session_manager import EarningsManager, SessionManager
from services.referral_observability import log_referral_milestone

logger = logging.getLogger(__name__)

# Fixed product rules (catoshi) — single source of truth
REFERRAL_BONUS_CATOSHI = 10_000_000
REFERRAL_REQUIRED_MINED_DAYS = 30
REFERRAL_REQUIRED_MINING_REWARD_CATOSHI = 300_000_000
REFERRAL_REQUIRED_GAME_REWARD_CATOSHI = 10_000

# Back-compat aliases
MINED_DAYS_REQUIRED = REFERRAL_REQUIRED_MINED_DAYS
MINING_REWARD_REQUIRED = REFERRAL_REQUIRED_MINING_REWARD_CATOSHI
GAME_REWARD_REQUIRED = REFERRAL_REQUIRED_GAME_REWARD_CATOSHI
DEFAULT_BONUS_CATOSHI = REFERRAL_BONUS_CATOSHI


async def get_referral_milestone_bonus_catoshi(db: AsyncSession) -> int:
    """Configured one-time milestone bonus (catoshi); falls back to code default."""
    cfg = await SessionManager.get_admin_config(db)
    v = getattr(cfg, "referral_milestone_bonus_catoshi", None)
    if v is None:
        return REFERRAL_BONUS_CATOSHI
    try:
        return max(0, int(v))
    except (TypeError, ValueError):
        return REFERRAL_BONUS_CATOSHI


# PostgreSQL advisory lock keys (two int4) — single-runner reconciliation
REFERRAL_RECONCILIATION_LOCK_KEY1 = 8_847_291
REFERRAL_RECONCILIATION_LOCK_KEY2 = 5_520_143
_ADV_LOCK_K1 = REFERRAL_RECONCILIATION_LOCK_KEY1
_ADV_LOCK_K2 = REFERRAL_RECONCILIATION_LOCK_KEY2


@dataclasses.dataclass(frozen=True)
class ReferralLiveMetrics:
    """Pure read model: live counts and eligibility (no DB writes)."""

    mined_days_count: int
    mining_reward_catoshi: int
    game_reward_catoshi: int
    condition_mined_met: bool
    condition_mining_met: bool
    condition_game_met: bool
    conditions_met_count: int
    eligible: bool


async def _count_mined_days(db: AsyncSession, referee_id: UUID) -> int:
    day_bucket = func.date_trunc(
        "day",
        func.coalesce(
            models.MiningSession.completed_at,
            models.MiningSession.end_time,
        ),
    )
    q = (
        select(func.count(func.distinct(day_bucket)))
        .where(
            models.MiningSession.user_id == referee_id,
            models.MiningSession.session_type == models.SessionType.BASE,
            models.MiningSession.status == models.MiningStatus.COMPLETED,
            models.MiningSession.total_earned > 0,
        )
    )
    r = await db.execute(q)
    return int(r.scalar() or 0)


async def _sum_mining_base_catoshi(db: AsyncSession, referee_id: UUID) -> int:
    r = await db.execute(
        select(func.coalesce(func.sum(models.EarningsLedger.amount), 0)).where(
            models.EarningsLedger.user_id == referee_id,
            models.EarningsLedger.reward_type == models.RewardType.MINING_BASE,
        )
    )
    return int(float(r.scalar() or 0))


async def _sum_game_reward_catoshi(db: AsyncSession, referee_id: UUID) -> int:
    r = await db.execute(
        select(func.coalesce(func.sum(models.GameReward.reward_catoshi), 0)).where(
            models.GameReward.user_id == referee_id
        )
    )
    return int(r.scalar() or 0)


def _conditions_met(
    mined_days: int, mining_cat: int, game_cat: int
) -> tuple[int, bool, bool, bool]:
    c1 = mined_days >= REFERRAL_REQUIRED_MINED_DAYS
    c2 = mining_cat >= REFERRAL_REQUIRED_MINING_REWARD_CATOSHI
    c3 = game_cat >= REFERRAL_REQUIRED_GAME_REWARD_CATOSHI
    return (sum([c1, c2, c3]), c1, c2, c3)


async def read_referral_live_metrics(
    db: AsyncSession, referee_user_id: UUID
) -> ReferralLiveMetrics:
    """
    Read-only: compute mined days, mining/game totals, per-condition flags, eligibility.
    Does not mutate the database.
    """
    md = await _count_mined_days(db, referee_user_id)
    m = await _sum_mining_base_catoshi(db, referee_user_id)
    g = await _sum_game_reward_catoshi(db, referee_user_id)
    met_count, c1, c2, c3 = _conditions_met(md, m, g)
    eligible = met_count == 3
    return ReferralLiveMetrics(
        mined_days_count=md,
        mining_reward_catoshi=m,
        game_reward_catoshi=g,
        condition_mined_met=c1,
        condition_mining_met=c2,
        condition_game_met=c3,
        conditions_met_count=met_count,
        eligible=eligible,
    )


async def get_referral_live_metrics(
    db: AsyncSession, referee_id: UUID
) -> tuple[int, int, int]:
    """Backward-compat tuple (mined_days, mining_cat, game_cat). Prefer read_referral_live_metrics."""
    m = await read_referral_live_metrics(db, referee_id)
    return (m.mined_days_count, m.mining_reward_catoshi, m.game_reward_catoshi)


async def refresh_referral_bonus_snapshot(
    db: AsyncSession,
    referral_id: UUID,
    *,
    force_recalc: bool = False,
    resume_from_review: bool = False,
    trigger: Optional[str] = None,
) -> models.Referral:
    """
    Recompute metrics and update snapshot columns + pending/eligible status only.

    Never creates ledger entries, never sets bonus_awarded_at, never credits payout.
    """
    res = await db.execute(
        select(models.Referral)
        .where(models.Referral.id == referral_id)
        .with_for_update()
    )
    ref = res.scalars().first()
    if not ref:
        raise HTTPException(status_code=404, detail="Referral not found")

    referee_id = ref.referee_user_id
    metrics = await read_referral_live_metrics(db, referee_id)
    mined_days = metrics.mined_days_count
    mining_cat = metrics.mining_reward_catoshi
    game_cat = metrics.game_reward_catoshi
    met_count = metrics.conditions_met_count
    all_met = metrics.eligible

    ref.mined_days_count = mined_days
    ref.mining_reward_catoshi = mining_cat
    ref.game_reward_catoshi = game_cat
    ref.conditions_met_count = met_count
    ref.last_evaluated_at = datetime.utcnow()

    st = (ref.bonus_status or "pending").lower()

    if st == "rewarded":
        await db.flush()
        return ref

    if st == "under_review":
        if resume_from_review:
            ref.bonus_status = "pending"
            st = "pending"
        elif not force_recalc:
            await db.flush()
            return ref
        else:
            await db.flush()
            return ref

    if st == "rejected":
        if not force_recalc:
            await db.flush()
            return ref
        if all_met:
            ref.bonus_status = "pending"
            st = "pending"
        else:
            await db.flush()
            return ref

    if all_met and st != "rejected":
        if st != "eligible":
            ref.bonus_status = "eligible"
            ref.bonus_eligible_at = datetime.utcnow()
            if trigger is not None:
                log_referral_milestone(
                    "referral_became_eligible",
                    referral_id=str(ref.id),
                    referrer_user_id=str(ref.referrer_user_id),
                    referee_user_id=str(ref.referee_user_id),
                    old_status=st,
                    new_status="eligible",
                    trigger=trigger,
                )
    else:
        if st != "rejected" or force_recalc:
            ref.bonus_status = "pending"
            ref.bonus_eligible_at = None

    await db.flush()
    return ref


async def evaluate_referral_bonus(
    db: AsyncSession,
    referral_id: UUID,
    *,
    force_recalc: bool = False,
    allow_award: bool = True,
    resume_from_review: bool = False,
    trigger: str = "unspecified",
) -> models.Referral:
    """
    Orchestrates snapshot refresh then optional payout.

    Only ``award_referral_bonus`` inserts ledger / sets bonus_awarded_at.
    Pass ``allow_award=False`` for read-only paths (e.g. callers that only refresh snapshots).
    Mining/game hooks and reconciliation pass ``allow_award=True`` for auto-award when eligible.
    """
    ref = await refresh_referral_bonus_snapshot(
        db,
        referral_id,
        force_recalc=force_recalc,
        resume_from_review=resume_from_review,
        trigger=trigger,
    )
    if (
        allow_award
        and (ref.bonus_status or "").lower() == "eligible"
        and ref.bonus_awarded_at is None
    ):
        await award_referral_bonus(db, referral_id, commit=False, trigger=trigger)
        await db.flush()
        ref = (
            await db.execute(select(models.Referral).where(models.Referral.id == referral_id))
        ).scalars().first()
    return ref


async def award_referral_bonus(
    db: AsyncSession,
    referral_id: UUID,
    *,
    commit: bool = True,
    admin_user_id: Optional[UUID] = None,
    admin_note: Optional[str] = None,
    force: bool = False,
    trigger: str = "unspecified",
) -> models.Referral:
    """
    Sole code path that credits REFERRAL_BONUS, sets bonus_awarded_at, marks rewarded.
    """
    res = await db.execute(
        select(models.Referral)
        .where(models.Referral.id == referral_id)
        .with_for_update()
    )
    ref = res.scalars().first()
    if not ref:
        raise HTTPException(status_code=404, detail="Referral not found")

    if ref.bonus_awarded_at is not None:
        raise HTTPException(status_code=400, detail="Referral bonus already awarded")

    metrics = await read_referral_live_metrics(db, ref.referee_user_id)
    all_met = metrics.eligible

    if not force:
        if (ref.bonus_status or "").lower() != "eligible":
            raise HTTPException(
                status_code=400,
                detail="Referral is not eligible for bonus",
            )
        if not all_met:
            raise HTTPException(
                status_code=400,
                detail="Eligibility conditions are no longer met",
            )
    else:
        if not admin_user_id:
            raise HTTPException(
                status_code=400,
                detail="Admin user required for force award",
            )

    amount = int(ref.bonus_amount_catoshi or REFERRAL_BONUS_CATOSHI)
    desc = (
        f"Referral milestone bonus (referee {ref.referee_user_id})"
        + (f" [admin force: {admin_note}]" if admin_note else "")
    )
    entry = await EarningsManager.create_reward_entry(
        user_id=str(ref.referrer_user_id),
        amount=float(amount),
        reward_type=models.RewardType.REFERRAL_BONUS,
        description=desc,
        db=db,
        commit=False,
        referral_id=ref.id,
    )

    old_award_status = (ref.bonus_status or "pending").lower()
    ref.bonus_status = "rewarded"
    ref.bonus_awarded_at = datetime.utcnow()
    ref.bonus_awarded_txn_id = entry.id
    if force and admin_user_id:
        ref.bonus_reviewed_by = admin_user_id
        ref.bonus_reviewed_at = datetime.utcnow()

    event = "referral_force_awarded" if force else "referral_auto_awarded"
    log_referral_milestone(
        event,
        referral_id=str(ref.id),
        referrer_user_id=str(ref.referrer_user_id),
        referee_user_id=str(ref.referee_user_id),
        old_status=old_award_status,
        new_status="rewarded",
        trigger=trigger,
        amount_catoshi=amount,
        admin_note=admin_note if force else None,
    )

    await db.flush()
    if commit:
        await db.commit()
        await db.refresh(ref)
    return ref


# Explicit INT casts: without them, drivers may bind bigint and PostgreSQL picks the
# single-argument pg_*_advisory_lock(bigint) overload — a different lock than (int4, int4).
REFERRAL_RECONCILIATION_ADVISORY_LOCK_TRY_SQL = (
    "SELECT pg_try_advisory_lock(CAST(:k1 AS INT), CAST(:k2 AS INT))"
)
REFERRAL_RECONCILIATION_ADVISORY_LOCK_UNLOCK_SQL = (
    "SELECT pg_advisory_unlock(CAST(:k1 AS INT), CAST(:k2 AS INT))"
)
REFERRAL_RECONCILIATION_ADVISORY_LOCK_HOLD_SQL = (
    "SELECT pg_advisory_lock(CAST(:k1 AS INT), CAST(:k2 AS INT))"
)


async def _try_reconciliation_advisory_lock(db: AsyncSession) -> bool:
    r = await db.execute(
        text(REFERRAL_RECONCILIATION_ADVISORY_LOCK_TRY_SQL),
        {"k1": _ADV_LOCK_K1, "k2": _ADV_LOCK_K2},
    )
    return bool(r.scalar())


async def _release_reconciliation_advisory_lock(db: AsyncSession) -> None:
    await db.execute(
        text(REFERRAL_RECONCILIATION_ADVISORY_LOCK_UNLOCK_SQL),
        {"k1": _ADV_LOCK_K1, "k2": _ADV_LOCK_K2},
    )


async def _run_referral_bonus_reconciliation_inner(db: AsyncSession) -> int:
    res = await db.execute(
        select(models.Referral.id).where(models.Referral.bonus_awarded_at.is_(None))
    )
    ids = [row[0] for row in res.all()]
    processed = 0
    for rid in ids:
        try:
            await evaluate_referral_bonus(
                db,
                rid,
                force_recalc=False,
                allow_award=True,
                trigger="reconciliation",
            )
            await db.commit()
            processed += 1
        except Exception:
            await db.rollback()
            logger.exception("referral reconciliation failed for %s", rid)
    return processed


async def run_referral_bonus_reconciliation(db: AsyncSession) -> int:
    """
    Re-evaluate unpaid referrals with optional payout. Uses DB advisory lock so only
    one runner (per cluster) executes the scan at a time.
    """
    if not await _try_reconciliation_advisory_lock(db):
        log_referral_milestone(
            "reconciliation_skipped_lock",
            trigger="reconciliation",
            lock_key1=_ADV_LOCK_K1,
            lock_key2=_ADV_LOCK_K2,
        )
        return 0
    try:
        n = await _run_referral_bonus_reconciliation_inner(db)
        log_referral_milestone(
            "reconciliation_run",
            trigger="reconciliation",
            rows_processed=n,
        )
        return n
    finally:
        await _release_reconciliation_advisory_lock(db)


async def recalculate_for_referee(
    db: AsyncSession, referee_user_id: UUID, *, trigger: str = "mining_event"
) -> None:
    res = await db.execute(
        select(models.Referral.id).where(models.Referral.referee_user_id == referee_user_id)
    )
    for row in res.all():
        rid = row[0]
        try:
            await evaluate_referral_bonus(
                db, rid, force_recalc=False, allow_award=True, trigger=trigger
            )
        except Exception as e:
            logger.warning("referral_bonus evaluate failed for %s: %s", rid, e)


def append_referral_admin_audit(
    ref: models.Referral,
    *,
    admin_user_id: UUID,
    action: str,
    note: Optional[str] = None,
) -> None:
    ts = datetime.utcnow().isoformat() + "Z"
    line = f"[{ts}] {action} admin={admin_user_id}"
    if note:
        line += f" | {note}"
    line += "\n"
    ref.bonus_review_note = (ref.bonus_review_note or "") + line


async def ensure_referral_row(
    db: AsyncSession,
    referrer: models.User,
    referee: models.User,
    referred_at: Optional[datetime] = None,
    *,
    trigger: str = "unspecified",
) -> Optional[models.Referral]:
    if referrer.id == referee.id:
        return None
    res = await db.execute(
        select(models.Referral).where(
            models.Referral.referrer_user_id == referrer.id,
            models.Referral.referee_user_id == referee.id,
        )
    )
    existing = res.scalars().first()
    if existing:
        return existing
    bonus_cat = await get_referral_milestone_bonus_catoshi(db)
    ref = models.Referral(
        referrer_user_id=referrer.id,
        referee_user_id=referee.id,
        referred_at=referred_at or datetime.utcnow(),
        bonus_amount_catoshi=bonus_cat,
    )
    db.add(ref)
    await db.flush()
    log_referral_milestone(
        "referral_row_created",
        referral_id=str(ref.id),
        referrer_user_id=str(ref.referrer_user_id),
        referee_user_id=str(ref.referee_user_id),
        trigger=trigger,
    )
    return ref
