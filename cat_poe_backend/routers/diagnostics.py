"""Client-side error report intake.

The screen the user lands on when ``GET /auth/users/me`` fails at boot
(see cat_poe/lib/screens/auth_wrapper.dart) used to be invisible to
operators — no logs reached the server because the request never did.
This endpoint lets the client post a structured report so operators get
a heads-up. Email delivery is best-effort and configurable; see
``services/diagnostic_email.py``.

Notes:

- **Unauthenticated.** The very failure being reported may be an auth
  failure, so requiring a valid JWT would defeat the purpose. Per-IP
  rate-limiting and dedupe keep abuse manageable.
- **No DB writes.** Reports are logged + emailed only; if you later want
  trend analysis, add a ClientErrorReport model and persist here.
- **Fail-soft.** Mail send failure does not 5xx the endpoint — the
  client doesn't care, and retrying won't help.
"""
from __future__ import annotations

import asyncio
import logging
from time import monotonic
from typing import Optional

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

import database
import schemas
from services import auth_rate_limit
from services.diagnostic_email import maybe_send_report

router = APIRouter(prefix="/v1/diagnostics", tags=["diagnostics"])
logger = logging.getLogger(__name__)

# Per-(user_id|fingerprint) dedupe window. Storms during real outages hit
# the same fingerprint thousands of times in seconds — we don't need that
# many emails.
_DEDUPE_TTL_SECONDS = 3600.0
_dedupe_cache: dict[str, float] = {}
_dedupe_lock = asyncio.Lock()


async def _is_duplicate(fingerprint: str, user_id: Optional[str]) -> bool:
    key = f"{user_id or 'anon'}|{fingerprint}"
    now = monotonic()
    async with _dedupe_lock:
        # Lazy GC: drop entries older than the TTL so the cache doesn't grow
        # unbounded under heavy traffic.
        expired = [k for k, ts in _dedupe_cache.items() if now - ts > _DEDUPE_TTL_SECONDS]
        for k in expired:
            _dedupe_cache.pop(k, None)
        last = _dedupe_cache.get(key)
        if last is not None and now - last <= _DEDUPE_TTL_SECONDS:
            return True
        _dedupe_cache[key] = now
        return False


@router.post(
    "/client-error",
    response_model=schemas.ClientErrorAck,
    status_code=status.HTTP_202_ACCEPTED,
)
async def report_client_error(
    payload: schemas.ClientErrorReport,
    request: Request,
    db: AsyncSession = Depends(database.get_db),
) -> schemas.ClientErrorAck:
    """Accept a client-side error report. Best-effort emails it onward."""

    # Per-IP rate-limit. Conservative because reports are heavyweight (SMTP).
    client_ip = auth_rate_limit.client_ip_from_request(request)
    await auth_rate_limit.enforce_rate_limit(
        f"diagnostics_client_error:{client_ip}",
        max_events=10,
        window_seconds=3600.0,
    )

    user_id_str = str(payload.user_id) if payload.user_id else None

    if await _is_duplicate(payload.fingerprint, user_id_str):
        logger.info(
            "diagnostics: deduped report fingerprint=%s user_id=%s ip=%s",
            payload.fingerprint,
            user_id_str,
            client_ip,
        )
        return schemas.ClientErrorAck(
            accepted=True, deduplicated=True, emailed=False
        )

    logger.info(
        "diagnostics: accepted report fingerprint=%s user_id=%s "
        "platform=%s app_version=%s http_status=%s ip=%s",
        payload.fingerprint,
        user_id_str,
        payload.platform,
        payload.app_version,
        payload.http_status,
        client_ip,
    )

    report_dict = payload.model_dump(mode="json")
    emailed = False
    try:
        emailed = await maybe_send_report(report_dict, db)
    except Exception as exc:  # noqa: BLE001 — never 5xx the diagnostic path
        logger.warning("diagnostics: mail send raised unexpectedly: %s", exc)
        emailed = False

    return schemas.ClientErrorAck(
        accepted=True, deduplicated=False, emailed=emailed
    )
