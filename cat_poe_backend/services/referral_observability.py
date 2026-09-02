"""Structured INFO logs for referral milestone flows (metrics / log aggregation friendly)."""

from __future__ import annotations

import json
import logging
from typing import Any, Optional
from uuid import UUID

logger = logging.getLogger(__name__)


def _json_safe(value: Any) -> Any:
    if isinstance(value, UUID):
        return str(value)
    return value


def log_referral_milestone(event: str, **fields: Any) -> None:
    """
    Emit one JSON object per line with prefix ``referral_milestone`` for grep and parsers.

    Common fields: referral_id, referrer_user_id, referee_user_id, old_status, new_status,
    trigger (e.g. signup, mining_event, game_event, admin_recalculate, reconciliation,
    user_get_detail, admin_get_detail).
    """
    payload: dict[str, Any] = {"event": event}
    for k, v in fields.items():
        if v is None:
            continue
        payload[k] = _json_safe(v)
    logger.info("referral_milestone %s", json.dumps(payload, default=str, sort_keys=True))
