"""Social ID lock, mission reward revoke, and verification audit helpers."""
from __future__ import annotations

from datetime import datetime
from typing import List, Optional, Tuple

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

import models


def platform_from_mission_icon(icon: Optional[str]) -> Optional[str]:
    if not icon:
        return None
    t = icon.lower().strip()
    if "discord" in t:
        return "discord"
    if "telegram" in t:
        return "telegram"
    if "facebook" in t:
        return "facebook"
    if "whatsapp" in t:
        return "whatsapp"
    if "twitter" in t or "tweet" in t or t == "x":
        return "x"
    return None


async def write_audit(
    db: AsyncSession,
    user_id,
    action: str,
    platform: Optional[str],
    detail: Optional[str],
    amount: Optional[float] = None,
) -> None:
    row = models.SocialVerificationAudit(
        user_id=user_id,
        action=action,
        platform=platform,
        detail=(detail or "")[:1000] if detail else None,
        amount=amount,
        created_at=datetime.utcnow(),
    )
    db.add(row)


async def mission_ids_for_platform(db: AsyncSession, platform: str) -> List:
    result = await db.execute(select(models.Mission))
    missions = result.scalars().all()
    out = []
    for m in missions:
        if platform_from_mission_icon(m.icon) == platform:
            out.append(m.id)
    return out


async def revoke_platform_mission_rewards(
    db: AsyncSession,
    user: models.User,
    platform: str,
    reason: str,
    *,
    extra_detail: str = "",
) -> float:
    """
    Remove COMPLETED user_missions for missions tied to this platform,
    subtract granted rewards from balance/total_earnings, add negative ledger row.
    Returns the positive amount revoked (0 if nothing to revoke).
    """
    mission_ids = await mission_ids_for_platform(db, platform)
    if not mission_ids:
        await write_audit(
            db,
            user.id,
            "REWARD_REVOKED",
            platform,
            f"reason={reason} revoked_amount=0 no_missions {extra_detail}".strip(),
            0.0,
        )
        return 0.0

    um_result = await db.execute(
        select(models.UserMission, models.Mission)
        .join(models.Mission, models.UserMission.mission_id == models.Mission.id)
        .where(models.UserMission.user_id == user.id)
        .where(models.UserMission.mission_id.in_(mission_ids))
        .where(models.UserMission.status == "COMPLETED")
    )
    rows = um_result.all()
    amount = 0.0
    mission_codes: List[str] = []
    for um, mission in rows:
        amount += float(mission.reward_amount or 0.0)
        if mission.code:
            mission_codes.append(mission.code)

    if rows:
        await db.execute(
            delete(models.UserMission).where(
                models.UserMission.user_id == user.id,
                models.UserMission.mission_id.in_(mission_ids),
                models.UserMission.status == "COMPLETED",
            )
        )

    if amount > 0:
        desc = (
            f"Revoked mission rewards reason={reason} platform={platform} "
            f"amount={amount} missions={','.join(mission_codes)} {extra_detail}"
        ).strip()[:500]
        ledger = models.EarningsLedger(
            user_id=user.id,
            aggregation_date=datetime.utcnow().date(),
            amount=-amount,
            reward_type=models.RewardType.MISSION_COMPLETION,
            description=desc,
        )
        db.add(ledger)
        user.balance = max(0.0, (user.balance or 0.0) - amount)
        user.total_earnings = max(0.0, (user.total_earnings or 0.0) - amount)
        db.add(user)

    await write_audit(
        db,
        user.id,
        "REWARD_REVOKED",
        platform,
        f"reason={reason} revoked_amount={amount} missions={','.join(mission_codes)} {extra_detail}".strip(),
        amount,
    )
    return amount


def apply_social_verified_and_locked(
    user: models.User,
    mission_icon: Optional[str],
    proof: Optional[str],
) -> None:
    platform = platform_from_mission_icon(mission_icon)
    if not platform:
        return
    id_attr = f"{platform}_id"
    verified_attr = f"{platform}_id_verified"
    locked_attr = f"{platform}_id_locked"
    if proof and str(proof).strip():
        cur = getattr(user, id_attr)
        if not cur:
            setattr(user, id_attr, str(proof).strip())
    setattr(user, verified_attr, True)
    setattr(user, locked_attr, True)


SOCIAL_FIELD_PREFIXES: Tuple[Tuple[str, str], ...] = (
    ("discord_id", "discord"),
    ("telegram_id", "telegram"),
    ("x_id", "x"),
    ("facebook_id", "facebook"),
    ("whatsapp_id", "whatsapp"),
)


def normalize_social_value(val) -> Optional[str]:
    """
    Canonical stored / compared form for social handles on profiles.

    - Trims whitespace
    - Drops a single leading '@' (common for X/Twitter handles)
    - Lowercases for stable equality (duplicate checks, fraud noise reduction)

    Not for raw display-only strings; use this for persisted IDs and comparisons.
    """
    if val is None:
        return None
    s = str(val).strip()
    if not s:
        return None
    if s.startswith("@"):
        s = s[1:].strip()
    if not s:
        return None
    return s.lower()
