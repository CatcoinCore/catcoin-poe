"""
Single source of truth for admin engagement windows and ping dedupe.

- **Admin "active" user** (list filter, summary, inactive ping): `last_active_at`
  within the last `ADMIN_LAST_ACTIVE_ENGAGEMENT_THRESHOLD_HOURS` hours (UTC, naive).
- **Ping dedupe lookback** defaults to the same hours so "recently nudged" aligns with
  the same clock used for inactivity; change independently if product requires it.
"""
from __future__ import annotations

from datetime import timedelta

ADMIN_LAST_ACTIVE_ENGAGEMENT_THRESHOLD_HOURS: int = 24

PING_NOTIFICATION_DEDUPE_LOOKBACK_HOURS: int = ADMIN_LAST_ACTIVE_ENGAGEMENT_THRESHOLD_HOURS

ADMIN_LAST_ACTIVE_ENGAGEMENT_WINDOW: timedelta = timedelta(
    hours=ADMIN_LAST_ACTIVE_ENGAGEMENT_THRESHOLD_HOURS
)

PING_NOTIFICATION_DEDUPE_WINDOW: timedelta = timedelta(
    hours=PING_NOTIFICATION_DEDUPE_LOOKBACK_HOURS
)
