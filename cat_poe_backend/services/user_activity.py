"""Admin user engagement: active vs inactive from `last_active_at` (not mining state).

Referral list "active" in the app is **mining-based** (see `SessionManager.get_available_referrals`);
this module is **app touch / last_active_at** only for admin UX and inactive-user nudges.
"""
from __future__ import annotations

from datetime import datetime

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

import models

from services.engagement_constants import ADMIN_LAST_ACTIVE_ENGAGEMENT_WINDOW


def activity_cutoff_utc(now: datetime | None = None) -> datetime:
    now = now or datetime.utcnow()
    return now - ADMIN_LAST_ACTIVE_ENGAGEMENT_WINDOW


def user_is_active_for_admin(user: models.User, *, now: datetime | None = None) -> bool:
    """True when `last_active_at` is within the configured engagement window (UTC naive)."""
    now = now or datetime.utcnow()
    la = user.last_active_at
    if la is None:
        return False
    return la >= now - ADMIN_LAST_ACTIVE_ENGAGEMENT_WINDOW


def last_active_active_clause(cutoff: datetime):
    """SQLAlchemy filter: *engagement* active (recent `last_active_at`) for admin lists."""
    return models.User.last_active_at >= cutoff


def last_active_inactive_clause(cutoff: datetime):
    """SQLAlchemy filter: *engagement* inactive for admin lists and inactive-user ping."""
    return or_(models.User.last_active_at.is_(None), models.User.last_active_at < cutoff)


async def admin_activity_counts(
    db: AsyncSession,
    *,
    cutoff: datetime,
    search: str | None = None,
    suspicious: bool | None = None,
    is_admin: bool | None = None,
) -> tuple[int, int, int]:
    """
    Returns (total_users, active_users, inactive_users) for non-deleted users,
    respecting search / suspicious / is_admin filters but **not** activity_status.

    Uses `ADMIN_LAST_ACTIVE_ENGAGEMENT_THRESHOLD_HOURS` from engagement_constants.
    """
    filters = []
    filters.append(
        or_(models.User.is_deleted == False, models.User.is_deleted.is_(None))  # noqa: E712
    )

    if search:
        sf = f"%{search}%"
        filters.append(
            (models.User.username.ilike(sf)) | (models.User.email.ilike(sf)),
        )
    if suspicious is not None:
        filters.append(models.User.is_suspicious == suspicious)
    if is_admin is not None:
        filters.append(models.User.is_admin == is_admin)

    base_where = and_(*filters) if filters else True

    total_q = select(func.count(models.User.id)).where(base_where)
    active_q = (
        select(func.count(models.User.id))
        .where(base_where)
        .where(last_active_active_clause(cutoff))
    )
    inactive_q = (
        select(func.count(models.User.id))
        .where(base_where)
        .where(last_active_inactive_clause(cutoff))
    )

    total = (await db.execute(total_q)).scalar() or 0
    active = (await db.execute(active_q)).scalar() or 0
    inactive = (await db.execute(inactive_q)).scalar() or 0
    return int(total), int(active), int(inactive)
