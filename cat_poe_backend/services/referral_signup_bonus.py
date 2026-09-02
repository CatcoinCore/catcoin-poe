"""Credit Catoshi bonuses when a user joins with a valid referral code (email verified)."""
from __future__ import annotations

from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

import models
from services.session_manager import EarningsManager, SessionManager

_WELCOME_PREFIX = "Welcome bonus: referred by code "
_INVITE_PREFIX = "Invite bonus: referred user "


def _amounts_from_config(config: models.AdminConfig) -> tuple[float, float]:
    ref = getattr(config, "referral_signup_bonus_referee_amount", None)
    inv = getattr(config, "referral_signup_bonus_referrer_amount", None)
    try:
        referee = float(ref) if ref is not None else 100.0
    except (TypeError, ValueError):
        referee = 100.0
    try:
        referrer = float(inv) if inv is not None else 50.0
    except (TypeError, ValueError):
        referrer = 50.0
    return referee, referrer


async def _referee_welcome_already_granted(db: AsyncSession, user_id: UUID) -> bool:
    r = await db.execute(
        select(func.count(models.EarningsLedger.id))
        .where(models.EarningsLedger.user_id == user_id)
        .where(models.EarningsLedger.reward_type == models.RewardType.REFERRAL_SIGNUP_BONUS)
        .where(models.EarningsLedger.description.like(f"{_WELCOME_PREFIX}%"))
    )
    return (r.scalar() or 0) > 0


async def _invite_bonus_already_granted(
    db: AsyncSession, referrer_id: UUID, invitee_id: UUID
) -> bool:
    desc = f"{_INVITE_PREFIX}{invitee_id}"
    r = await db.execute(
        select(models.EarningsLedger.id)
        .where(models.EarningsLedger.user_id == referrer_id)
        .where(models.EarningsLedger.reward_type == models.RewardType.REFERRAL_SIGNUP_BONUS)
        .where(models.EarningsLedger.description == desc)
        .limit(1)
    )
    return r.scalars().first() is not None


async def grant_referral_signup_bonuses(
    db: AsyncSession,
    invitee: models.User,
) -> None:
    """
    If ``invitee.referred_by`` matches a live referrer, credit:
    - **Referee** (new user): welcome Catoshi once.
    - **Referrer**: invite reward once per invited user.

    Idempotent via ledger descriptions. Does **not** commit; caller must ``commit`` the session.

    Only runs for **email-verified** users so unverified signups cannot farm bonuses.
    """
    if not getattr(invitee, "email_verified", False):
        return

    code = (invitee.referred_by or "").strip().lower()
    if not code:
        return

    config = await SessionManager.get_admin_config(db)
    referee_amt, referrer_amt = _amounts_from_config(config)
    if referee_amt <= 0 and referrer_amt <= 0:
        return

    result = await db.execute(
        select(models.User).where(func.lower(models.User.referral_code) == code)
    )
    referrer = result.scalars().first()
    if not referrer:
        return
    if getattr(referrer, "is_deleted", False):
        return
    if referrer.id == invitee.id:
        return

    invitee_id_str = str(invitee.id)
    referrer_id_str = str(referrer.id)

    if referee_amt > 0 and not await _referee_welcome_already_granted(db, invitee.id):
        await EarningsManager.create_reward_entry(
            invitee_id_str,
            referee_amt,
            models.RewardType.REFERRAL_SIGNUP_BONUS,
            f"{_WELCOME_PREFIX}{code}",
            db,
            commit=False,
        )

    if referrer_amt > 0 and not await _invite_bonus_already_granted(
        db, referrer.id, invitee.id
    ):
        await EarningsManager.create_reward_entry(
            referrer_id_str,
            referrer_amt,
            models.RewardType.REFERRAL_SIGNUP_BONUS,
            f"{_INVITE_PREFIX}{invitee.id}",
            db,
            commit=False,
        )
