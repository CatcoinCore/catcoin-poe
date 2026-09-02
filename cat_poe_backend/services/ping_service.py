"""In-app ping rows (not device push): reminders stored for future delivery/UX."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import List, Sequence

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

import models
from services.engagement_constants import PING_NOTIFICATION_DEDUPE_WINDOW

PING_KIND_REFERRAL_BULK = "REFERRAL_BULK"
PING_KIND_ADMIN_INACTIVE = "ADMIN_INACTIVE_REMINDER"


@dataclass
class BulkPingResult:
    total_targets: int
    pinged: int
    skipped: int
    failed: int


async def _recipient_ids_recently_pinged(
    db: AsyncSession,
    *,
    recipient_ids: Sequence[uuid.UUID],
    sender_id: uuid.UUID | None,
    kind: str,
    since: datetime,
) -> set[uuid.UUID]:
    """Recipients who already have a row in the dedupe window (one query, no N+1)."""
    if not recipient_ids:
        return set()
    sender_clause = (
        models.UserPingNotification.sender_user_id == sender_id
        if sender_id is not None
        else models.UserPingNotification.sender_user_id.is_(None)
    )
    q = select(models.UserPingNotification.recipient_user_id).where(
        models.UserPingNotification.recipient_user_id.in_(list(recipient_ids)),
        models.UserPingNotification.kind == kind,
        models.UserPingNotification.created_at >= since,
        sender_clause,
    )
    r = await db.execute(q)
    return set(r.scalars().all())


async def record_pings_for_recipients(
    db: AsyncSession,
    *,
    recipient_ids: Sequence[uuid.UUID],
    sender_id: uuid.UUID | None,
    kind: str,
    now: datetime | None = None,
) -> BulkPingResult:
    """
    Insert at most one row per recipient. Skips recipients already pinged in
    PING_NOTIFICATION_DEDUPE_WINDOW (see engagement_constants).

    Does **not** send mobile push notifications — only persists in-app ping rows.
    """
    now = now or datetime.utcnow()
    since = now - PING_NOTIFICATION_DEDUPE_WINDOW
    ids: List[uuid.UUID] = list(dict.fromkeys(recipient_ids))
    total = len(ids)
    skipped = 0
    pinged = 0
    failed = 0

    dupes = await _recipient_ids_recently_pinged(
        db, recipient_ids=ids, sender_id=sender_id, kind=kind, since=since
    )

    to_insert: List[uuid.UUID] = []
    for rid in ids:
        if rid in dupes:
            skipped += 1
        else:
            to_insert.append(rid)

    for rid in to_insert:
        db.add(
            models.UserPingNotification(
                recipient_user_id=rid,
                sender_user_id=sender_id,
                kind=kind,
                created_at=now,
            )
        )
        pinged += 1

    try:
        await db.commit()
    except Exception:
        await db.rollback()
        return BulkPingResult(
            total_targets=total,
            pinged=0,
            skipped=skipped,
            failed=total - skipped,
        )

    return BulkPingResult(
        total_targets=total, pinged=pinged, skipped=skipped, failed=failed
    )
