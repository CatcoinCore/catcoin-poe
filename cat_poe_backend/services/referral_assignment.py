"""Server-side rules for referred_by / referral row creation (abuse prevention)."""
from __future__ import annotations

import logging
from typing import Any, Optional
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

import models

logger = logging.getLogger(__name__)

REFERRAL_ERR_ALREADY_SET = "referral_already_set"
REFERRAL_ERR_SELF = "referral_self_not_allowed"
REFERRAL_ERR_AFTER_ACTIVITY = "referral_not_allowed_after_activity"
REFERRAL_ERR_REFERRER_NOT_FOUND = "referral_referrer_not_found"
REFERRAL_ERR_HAS_REFERRAL_ROW = "referral_already_linked"


def _detail(error_code: str, message: str) -> dict[str, Any]:
    return {"error_code": error_code, "message": message}


async def referee_has_referral_row(db: AsyncSession, user_id: UUID) -> bool:
    r = await db.execute(
        select(models.Referral.id)
        .where(models.Referral.referee_user_id == user_id)
        .limit(1)
    )
    return r.scalar() is not None


async def referee_has_mining_base_earnings(db: AsyncSession, user_id: UUID) -> bool:
    r = await db.execute(
        select(func.coalesce(func.sum(models.EarningsLedger.amount), 0)).where(
            models.EarningsLedger.user_id == user_id,
            models.EarningsLedger.reward_type == models.RewardType.MINING_BASE,
        )
    )
    total = float(r.scalar() or 0)
    return total > 0


async def referee_has_game_rewards(db: AsyncSession, user_id: UUID) -> bool:
    r = await db.execute(
        select(func.coalesce(func.sum(models.GameReward.reward_catoshi), 0)).where(
            models.GameReward.user_id == user_id
        )
    )
    total = int(r.scalar() or 0)
    return total > 0


async def referee_has_meaningful_activity(db: AsyncSession, user_id: UUID) -> bool:
    """True if user already earned mining (MINING_BASE) or any game reward."""
    if await referee_has_mining_base_earnings(db, user_id):
        return True
    if await referee_has_game_rewards(db, user_id):
        return True
    return False


async def can_set_referred_by(
    db: AsyncSession,
    referee: models.User,
    *,
    referrer: Optional[models.User],
    proposed_code_lower: str,
) -> tuple[bool, Optional[dict[str, Any]]]:
    """
    Returns (ok, error_detail). error_detail is HTTPException-style ``detail`` dict.
    """
    existing = (referee.referred_by or "").strip().lower()
    if existing:
        if existing == proposed_code_lower:
            return (True, None)
        return (
            False,
            _detail(
                REFERRAL_ERR_ALREADY_SET,
                "Referrer is already set and cannot be changed",
            ),
        )

    if referrer is None:
        return (
            False,
            _detail(REFERRAL_ERR_REFERRER_NOT_FOUND, "Invalid or unknown referral code"),
        )

    if referrer.id == referee.id:
        return (
            False,
            _detail(REFERRAL_ERR_SELF, "You cannot use your own referral code"),
        )

    if (referrer.referral_code or "").strip().lower() == (
        referee.referral_code or ""
    ).strip().lower():
        return (
            False,
            _detail(REFERRAL_ERR_SELF, "You cannot use your own referral code"),
        )

    if await referee_has_referral_row(db, referee.id):
        return (
            False,
            _detail(
                REFERRAL_ERR_HAS_REFERRAL_ROW,
                "Referral link already exists for this account",
            ),
        )

    if await referee_has_meaningful_activity(db, referee.id):
        return (
            False,
            _detail(
                REFERRAL_ERR_AFTER_ACTIVITY,
                "Referral code can only be set before mining or game rewards are earned",
            ),
        )

    return (True, None)


def log_referral_audit(event: str, **kwargs: Any) -> None:
    logger.info("referral_assignment %s %s", event, kwargs)
