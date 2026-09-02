"""Admin APIs for referral milestone bonus (paths under /v1/admin/referrals)."""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

import auth
import database
import models
import schemas
from services.referral_bonus import (
    REFERRAL_BONUS_CATOSHI,
    append_referral_admin_audit,
    award_referral_bonus,
    evaluate_referral_bonus,
    read_referral_live_metrics,
    refresh_referral_bonus_snapshot,
)
from routers.referrals import _conditions_payload

router = APIRouter(prefix="/v1", tags=["admin", "referrals"])


def _status_ui_hint(st: str) -> str:
    s = (st or "").lower()
    return {
        "pending": "Pending conditions",
        "eligible": "Eligible for reward",
        "rewarded": "Reward credited",
        "under_review": "Under admin review",
        "rejected": "Rejected",
    }.get(s, st or "")


async def _admin_row(
    db: AsyncSession, ref: models.Referral
) -> schemas.AdminReferralBonusRowResponse:
    ur = await db.execute(select(models.User).where(models.User.id == ref.referrer_user_id))
    uref = await db.execute(select(models.User).where(models.User.id == ref.referee_user_id))
    referrer = ur.scalars().first()
    referee = uref.scalars().first()
    if not referrer or not referee:
        raise HTTPException(status_code=500, detail="Missing user for referral row")
    return schemas.AdminReferralBonusRowResponse(
        referral_id=ref.id,
        referrer_user_id=referrer.id,
        referrer_username=referrer.username,
        referee_user_id=referee.id,
        referee_username=referee.username,
        referred_at=ref.referred_at,
        bonus_status=ref.bonus_status or "pending",
        mined_days_count=int(ref.mined_days_count or 0),
        mining_reward_catoshi=int(ref.mining_reward_catoshi or 0),
        game_reward_catoshi=int(ref.game_reward_catoshi or 0),
        bonus_eligible_at=ref.bonus_eligible_at,
        bonus_awarded_at=ref.bonus_awarded_at,
        bonus_review_required=bool(ref.bonus_review_required),
        conditions_met_count=int(ref.conditions_met_count or 0),
    )


async def _build_admin_detail(
    db: AsyncSession,
    ref: models.Referral,
) -> schemas.AdminReferralDetailFullResponse:
    ur = await db.execute(select(models.User).where(models.User.id == ref.referrer_user_id))
    uref = await db.execute(select(models.User).where(models.User.id == ref.referee_user_id))
    referrer = ur.scalars().first()
    referee = uref.scalars().first()
    if not referrer or not referee:
        raise HTTPException(status_code=500, detail="Missing user for referral row")

    live = await read_referral_live_metrics(db, ref.referee_user_id)

    ledger_snip: Optional[schemas.ReferralBonusLedgerEntrySnippet] = None
    if ref.bonus_awarded_txn_id:
        lr = await db.execute(
            select(models.EarningsLedger).where(
                models.EarningsLedger.id == ref.bonus_awarded_txn_id
            )
        )
        le = lr.scalars().first()
        if le:
            rt = le.reward_type
            rt_s = rt.value if hasattr(rt, "value") else str(rt)
            ledger_snip = schemas.ReferralBonusLedgerEntrySnippet(
                id=le.id,
                amount=float(le.amount),
                reward_type=rt_s,
                created_at=le.created_at,
                description=le.description,
            )

    cond = _conditions_payload(ref)
    st = ref.bonus_status or "pending"

    return schemas.AdminReferralDetailFullResponse(
        referral_id=ref.id,
        referrer_user_id=referrer.id,
        referrer_username=referrer.username,
        referee_user_id=referee.id,
        referee_username=referee.username,
        referee_joined_at=referee.created_at,
        referred_at=ref.referred_at,
        bonus_amount_catoshi=int(ref.bonus_amount_catoshi or REFERRAL_BONUS_CATOSHI),
        bonus_status=st,
        bonus_eligible_at=ref.bonus_eligible_at,
        bonus_awarded_at=ref.bonus_awarded_at,
        conditions=cond,
        conditions_met_count=int(ref.conditions_met_count or 0),
        status_ui_hint=_status_ui_hint(st),
        live_mined_days=live.mined_days_count,
        live_mining_reward_catoshi=live.mining_reward_catoshi,
        live_game_reward_catoshi=live.game_reward_catoshi,
        last_evaluated_at=ref.last_evaluated_at,
        bonus_awarded_ledger=ledger_snip,
        bonus_review_required=bool(ref.bonus_review_required),
        bonus_review_note=ref.bonus_review_note,
        bonus_reviewed_by=ref.bonus_reviewed_by,
        bonus_reviewed_at=ref.bonus_reviewed_at,
    )


def _admin_referral_filters(
    *,
    status: Optional[str],
    referrer_user_id: Optional[uuid.UUID],
    referee_user_id: Optional[uuid.UUID],
    review_required: Optional[bool],
    rewarded_only: bool,
    eligible_only: bool,
):
    conds = []
    if status:
        conds.append(models.Referral.bonus_status == status)
    if referrer_user_id:
        conds.append(models.Referral.referrer_user_id == referrer_user_id)
    if referee_user_id:
        conds.append(models.Referral.referee_user_id == referee_user_id)
    if review_required is True:
        conds.append(models.Referral.bonus_review_required.is_(True))
    if review_required is False:
        conds.append(
            (models.Referral.bonus_review_required.is_(False))
            | (models.Referral.bonus_review_required.is_(None))
        )
    if rewarded_only:
        conds.append(models.Referral.bonus_status == "rewarded")
    if eligible_only:
        conds.append(models.Referral.bonus_status == "eligible")
    return conds


@router.get("/admin/referrals", response_model=schemas.AdminReferralListResponse)
async def admin_list_referrals(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    status: Optional[str] = Query(None, description="Filter by bonus_status"),
    referrer_user_id: Optional[uuid.UUID] = Query(None),
    referee_user_id: Optional[uuid.UUID] = Query(None),
    review_required: Optional[bool] = Query(None),
    rewarded_only: bool = Query(False),
    eligible_only: bool = Query(False),
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")

    conds = _admin_referral_filters(
        status=status,
        referrer_user_id=referrer_user_id,
        referee_user_id=referee_user_id,
        review_required=review_required,
        rewarded_only=rewarded_only,
        eligible_only=eligible_only,
    )

    count_stmt = select(func.count()).select_from(models.Referral)
    if conds:
        count_stmt = count_stmt.where(and_(*conds))
    total = int((await db.execute(count_stmt)).scalar() or 0)

    stmt = select(models.Referral).order_by(models.Referral.referred_at.desc())
    if conds:
        stmt = stmt.where(and_(*conds))
    stmt = stmt.offset(skip).limit(limit)

    res = await db.execute(stmt)
    refs = res.scalars().all()
    items = [await _admin_row(db, ref) for ref in refs]
    return schemas.AdminReferralListResponse(
        items=items, total=total, skip=skip, limit=limit
    )


@router.get(
    "/admin/referrals/{referral_id}",
    response_model=schemas.AdminReferralDetailFullResponse,
)
async def admin_get_referral(
    referral_id: uuid.UUID,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    await refresh_referral_bonus_snapshot(
        db, referral_id, force_recalc=True, trigger="admin_get_detail"
    )
    await db.commit()
    res = await db.execute(select(models.Referral).where(models.Referral.id == referral_id))
    ref = res.scalars().first()
    if not ref:
        raise HTTPException(status_code=404, detail="Not found")
    return await _build_admin_detail(db, ref)


@router.post("/admin/referrals/{referral_id}/recalculate")
async def admin_recalculate_referral(
    referral_id: uuid.UUID,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    ref = await evaluate_referral_bonus(
        db,
        referral_id,
        force_recalc=True,
        allow_award=True,
        resume_from_review=False,
        trigger="admin_recalculate",
    )
    append_referral_admin_audit(
        ref, admin_user_id=user.id, action="recalculate", note=None
    )
    await db.commit()
    return {"ok": True, "referral_id": str(referral_id)}


@router.post("/admin/referrals/{referral_id}/review")
async def admin_referral_review(
    referral_id: uuid.UUID,
    body: schemas.AdminReferralReviewRequest,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")

    action = (body.action or "").strip().lower()
    allowed = {"under_review", "approve", "reject", "force_credit"}
    if action not in allowed:
        raise HTTPException(
            status_code=400,
            detail=f"action must be one of: {', '.join(sorted(allowed))}",
        )

    res = await db.execute(select(models.Referral).where(models.Referral.id == referral_id))
    ref = res.scalars().first()
    if not ref:
        raise HTTPException(status_code=404, detail="Not found")

    if action == "under_review":
        ref.bonus_status = "under_review"
        ref.bonus_review_required = True
        append_referral_admin_audit(
            ref, admin_user_id=user.id, action="under_review", note=body.note
        )
        await db.commit()
        return {"ok": True, "referral_id": str(referral_id)}

    if action == "reject":
        ref.bonus_status = "rejected"
        ref.bonus_reviewed_by = user.id
        ref.bonus_reviewed_at = datetime.utcnow()
        append_referral_admin_audit(
            ref, admin_user_id=user.id, action="reject", note=body.note
        )
        await db.commit()
        return {"ok": True, "referral_id": str(referral_id)}

    if action == "approve":
        ref_out = await evaluate_referral_bonus(
            db,
            referral_id,
            force_recalc=True,
            allow_award=True,
            resume_from_review=True,
            trigger="admin_approve",
        )
        append_referral_admin_audit(
            ref_out, admin_user_id=user.id, action="approve", note=body.note
        )
        await db.commit()
        return {"ok": True, "referral_id": str(referral_id)}

    if action == "force_credit":
        if not (body.note and body.note.strip()):
            raise HTTPException(
                status_code=400, detail="note is required for force_credit"
            )
        ref_done = await award_referral_bonus(
            db,
            referral_id,
            commit=False,
            admin_user_id=user.id,
            admin_note=body.note.strip(),
            force=True,
            trigger="admin_force_credit",
        )
        append_referral_admin_audit(
            ref_done, admin_user_id=user.id, action="force_credit", note=body.note
        )
        await db.commit()
        return {"ok": True, "referral_id": str(referral_id)}

    raise HTTPException(status_code=400, detail="Unsupported action")
