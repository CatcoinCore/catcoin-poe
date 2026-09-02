"""Simple in-process sliding-window rate limits for auth endpoints (per process)."""

from __future__ import annotations

import asyncio
import os
from collections import defaultdict
from time import monotonic
from typing import DefaultDict, List

from fastapi import HTTPException, status

from config import settings

_timestamps: DefaultDict[str, List[float]] = defaultdict(list)
_lock = asyncio.Lock()


def _rate_limit_disabled() -> bool:
    if settings.DISABLE_AUTH_RATE_LIMIT:
        return True
    if os.environ.get("DISABLE_AUTH_RATE_LIMIT", "").lower() in ("1", "true", "yes"):
        return True
    return False


async def enforce_rate_limit(key: str, max_events: int, window_seconds: float) -> None:
    """Raise HTTP 429 if key has exceeded max_events in window_seconds."""
    if _rate_limit_disabled():
        return
    async with _lock:
        now = monotonic()
        cutoff = now - window_seconds
        bucket = _timestamps[key]
        bucket[:] = [t for t in bucket if t > cutoff]
        if len(bucket) >= max_events:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many requests. Try again later.",
            )
        bucket.append(now)


def client_ip_from_request(request) -> str:
    cf = request.headers.get("CF-Connecting-IP")
    if cf:
        return cf.split(",")[0].strip()
    xff = request.headers.get("X-Forwarded-For")
    if xff:
        return xff.split(",")[0].strip()
    if request.client:
        return request.client.host or "unknown"
    return "unknown"
