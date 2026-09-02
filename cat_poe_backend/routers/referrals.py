"""User-facing referral milestone bonus APIs."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

import auth
import database
import models
import schemas
from services.referral_bonus import (
    REFERRAL_REQUIRED_GAME_REWARD_CATOSHI,
    REFERRAL_REQUIRED_MINED_DAYS,
    REFERRAL_REQUIRED_MINING_REWARD_CATOSHI,
    read_referral_live_metrics,
    refresh_referral_bonus_snapshot,
)

router = APIRouter(prefix="/v1/referrals", tags=["referrals"])


def _status_ui_hint(st: str) -> str:
    s = (st or "").lower()
    return {
        "pending": "Pending conditions",
        "eligible": "Eligible for reward",
        "rewarded": "Reward credited",
        "under_review": "Under admin review",
        "rejected": "Rejected",
    }.get(s, st or "")


def _conditions_payload(ref: models.Referral) -> schemas.ReferralBonusConditionsResponse:
    md = int(ref.mined_days_count or 0)
    mr = int(ref.mining_reward_catoshi or 0)
    gr = int(ref.game_reward_catoshi or 0)
    return schemas.ReferralBonusConditionsResponse(
        mined_days=schemas.ReferralBonusMinedDaysCondition(
            current=md,
            required=REFERRAL_REQUIRED_MINED_DAYS,
            met=md >= REFERRAL_REQUIRED_MINED_DAYS,
        ),
        mining_reward=schemas.ReferralBonusMiningRewardCondition(
            current_catoshi=mr,
            required_catoshi=REFERRAL_REQUIRED_MINING_REWARD_CATOSHI,
            met=mr >= REFERRAL_REQUIRED_MINING_REWARD_CATOSHI,
        ),
        game_reward=schemas.ReferralBonusGameRewardCondition(
            current_catoshi=gr,
            required_catoshi=REFERRAL_REQUIRED_GAME_REWARD_CATOSHI,
            met=gr >= REFERRAL_REQUIRED_GAME_REWARD_CATOSHI,
        ),
    )


@router.get("", response_model=schemas.ReferralBonusListResponse)
async def list_referral_bonuses(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """Referrals where the current user is the referrer (milestone bonus list)."""
    res = await db.execute(
        select(models.Referral, models.User)
        .join(models.User, models.Referral.referee_user_id == models.User.id)
        .where(models.Referral.referrer_user_id == user.id)
        .order_by(models.Referral.referred_at.desc())
    )
    rows = res.all()
    items: list[schemas.ReferralListItemResponse] = []
    for ref, referee in rows:
        name = (referee.display_name or referee.username or "").strip() or referee.username
        items.append(
            schemas.ReferralListItemResponse(
                referral_id=ref.id,
                referee_user_id=referee.id,
                referee_name=name,
                referee_joined_at=referee.created_at,
                referred_at=ref.referred_at,
                bonus_amount_catoshi=int(ref.bonus_amount_catoshi or 0),
                bonus_status=ref.bonus_status or "pending",
                conditions_met_count=int(ref.conditions_met_count or 0),
            )
        )
    return schemas.ReferralBonusListResponse(items=items)


@router.get("/{referral_id}", response_model=schemas.ReferralDetailResponse)
async def get_referral_bonus_detail(
    referral_id: uuid.UUID,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    own = await db.execute(
        select(models.Referral.id).where(
            models.Referral.id == referral_id,
            models.Referral.referrer_user_id == user.id,
        )
    )
    if not own.scalar():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    # Snapshot refresh only — never payout on GET
    await refresh_referral_bonus_snapshot(
        db, referral_id, force_recalc=True, trigger="user_get_detail"
    )
    await db.commit()
    res = await db.execute(
        select(models.Referral, models.User)
        .join(models.User, models.Referral.referee_user_id == models.User.id)
        .where(
            models.Referral.id == referral_id,
            models.Referral.referrer_user_id == user.id,
        )
    )
    row = res.first()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    ref, referee = row
    name = (referee.display_name or referee.username or "").strip() or referee.username
    live = await read_referral_live_metrics(db, ref.referee_user_id)
    cond = schemas.ReferralBonusConditionsResponse(
        mined_days=schemas.ReferralBonusMinedDaysCondition(
            current=live.mined_days_count,
            required=REFERRAL_REQUIRED_MINED_DAYS,
            met=live.condition_mined_met,
        ),
        mining_reward=schemas.ReferralBonusMiningRewardCondition(
            current_catoshi=live.mining_reward_catoshi,
            required_catoshi=REFERRAL_REQUIRED_MINING_REWARD_CATOSHI,
            met=live.condition_mining_met,
        ),
        game_reward=schemas.ReferralBonusGameRewardCondition(
            current_catoshi=live.game_reward_catoshi,
            required_catoshi=REFERRAL_REQUIRED_GAME_REWARD_CATOSHI,
            met=live.condition_game_met,
        ),
    )
    met = live.conditions_met_count
    st = ref.bonus_status or "pending"
    return schemas.ReferralDetailResponse(
        referral_id=ref.id,
        referrer_user_id=ref.referrer_user_id,
        referee_user_id=ref.referee_user_id,
        referee_name=name,
        referee_joined_at=referee.created_at,
        referred_at=ref.referred_at,
        bonus_amount_catoshi=int(ref.bonus_amount_catoshi or 0),
        bonus_status=st,
        bonus_awarded_at=ref.bonus_awarded_at,
        conditions=cond,
        conditions_met_count=met,
        status_ui_hint=_status_ui_hint(st),
    )
