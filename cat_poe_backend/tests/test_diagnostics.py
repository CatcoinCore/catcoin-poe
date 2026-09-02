"""Tests for POST /v1/diagnostics/client-error.

Cover the four behaviours operators rely on:
    * happy-path accepts and returns 202
    * per-IP rate-limit returns 429 after the threshold
    * dedupe within the window returns 202 + deduplicated=true (no second mail)
    * no target email configured → endpoint still 202 but emailed=false
"""

import pytest
from httpx import ASGITransport, AsyncClient

from database import get_db
from main import app
from routers import diagnostics as diagnostics_router
from services import auth_rate_limit, diagnostic_email


@pytest.fixture
def _clear_diagnostics_state():
    """Reset per-IP rate-limit + dedupe between tests so order doesn't matter."""
    auth_rate_limit._timestamps.clear()
    diagnostics_router._dedupe_cache.clear()
    yield
    auth_rate_limit._timestamps.clear()
    diagnostics_router._dedupe_cache.clear()


def _sample_payload(fingerprint: str = "auth_resume_blocked"):
    return {
        "fingerprint": fingerprint,
        "user_id": "5f2c8c6c-8e6a-4e6a-9d4c-2c0c8a1c9b3a",
        "app_version": "1.10.7+105",
        "platform": "android",
        "os_version": "Android 13",
        "locale": "en",
        "screen": "auth_wrapper",
        "error_class": "ApiTransientBackendException",
        "error_message": "Service unavailable. Please try again later.",
        "http_status": 503,
        "occurred_at": "2026-05-25T16:06:00Z",
        "breadcrumbs": ["boot", "checkAuth", "fetchUserProfile"],
    }


@pytest.mark.asyncio
async def test_happy_path_accepts_and_attempts_send(
    db_session, _clear_diagnostics_state, monkeypatch
):
    """A well-formed report returns 202 with accepted=true."""

    sent = []

    async def fake_send(report, db):
        sent.append(report)
        return True

    monkeypatch.setattr(diagnostic_email, "maybe_send_report", fake_send)
    # The router imports the symbol at module load, so we must also patch it
    # on the router's reference.
    monkeypatch.setattr(diagnostics_router, "maybe_send_report", fake_send)

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            resp = await client.post(
                "/v1/diagnostics/client-error", json=_sample_payload()
            )
        assert resp.status_code == 202
        body = resp.json()
        assert body["accepted"] is True
        assert body["deduplicated"] is False
        assert body["emailed"] is True
        assert len(sent) == 1
        assert sent[0]["fingerprint"] == "auth_resume_blocked"
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_rate_limit_returns_429_after_threshold(
    db_session, _clear_diagnostics_state, monkeypatch
):
    """Per-IP cap is 10/hour. The 11th request from the same IP must 429.

    The shared conftest sets ``DISABLE_AUTH_RATE_LIMIT=1`` to keep CI runs
    fast (auth fixtures hammer the same endpoints). We flip both the env
    var and the settings flag here so the limiter actually engages for the
    duration of this test.
    """
    import os
    from config import settings as live_settings

    monkeypatch.setenv("DISABLE_AUTH_RATE_LIMIT", "")
    monkeypatch.setattr(live_settings, "DISABLE_AUTH_RATE_LIMIT", False)
    # Sanity-check our override actually disengaged the bypass.
    assert not auth_rate_limit._rate_limit_disabled(), (
        "Test setup failed: rate limiter still bypassed via "
        f"env={os.environ.get('DISABLE_AUTH_RATE_LIMIT')!r}"
    )

    monkeypatch.setattr(
        diagnostics_router, "maybe_send_report",
        lambda report, db: _async_true(),
    )

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            # Each request has a unique fingerprint so dedupe doesn't fire.
            for i in range(10):
                resp = await client.post(
                    "/v1/diagnostics/client-error",
                    json=_sample_payload(fingerprint=f"fp_{i}"),
                )
                assert resp.status_code == 202, f"req {i} body={resp.text}"
            resp_11 = await client.post(
                "/v1/diagnostics/client-error",
                json=_sample_payload(fingerprint="fp_overflow"),
            )
            assert resp_11.status_code == 429
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_dedupe_returns_accepted_without_resending(
    db_session, _clear_diagnostics_state, monkeypatch
):
    """Submitting the same fingerprint twice in the window emails once."""

    send_calls = []

    async def fake_send(report, db):
        send_calls.append(report)
        return True

    monkeypatch.setattr(diagnostics_router, "maybe_send_report", fake_send)

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            first = await client.post(
                "/v1/diagnostics/client-error", json=_sample_payload()
            )
            second = await client.post(
                "/v1/diagnostics/client-error", json=_sample_payload()
            )
        assert first.status_code == 202
        assert first.json()["emailed"] is True
        assert second.status_code == 202
        assert second.json()["deduplicated"] is True
        assert second.json()["emailed"] is False
        # Only the first report should have reached the mail layer.
        assert len(send_calls) == 1
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_no_target_configured_still_returns_202(
    db_session, _clear_diagnostics_state, monkeypatch
):
    """When no email target is set, the endpoint accepts but does not mail.

    Exercises the real maybe_send_report — we stub out the SMTP attempt by
    making the target resolver return None.
    """
    from config import settings as live_settings

    monkeypatch.setattr(live_settings, "ERROR_REPORT_EMAIL", "")

    async def no_target(db):
        return None

    monkeypatch.setattr(diagnostic_email, "_resolve_target_email", no_target)

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            resp = await client.post(
                "/v1/diagnostics/client-error", json=_sample_payload()
            )
        assert resp.status_code == 202
        body = resp.json()
        assert body["accepted"] is True
        assert body["emailed"] is False
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.mark.asyncio
async def test_rejects_oversize_breadcrumbs(
    db_session, _clear_diagnostics_state
):
    """Pydantic schema bounds — > 20 breadcrumbs is a 422."""

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            payload = _sample_payload()
            payload["breadcrumbs"] = [f"step_{i}" for i in range(25)]
            resp = await client.post(
                "/v1/diagnostics/client-error", json=payload
            )
        assert resp.status_code == 422
    finally:
        app.dependency_overrides.pop(get_db, None)


# Small helper: returns an awaitable that resolves to True. Used by tests
# that monkeypatch maybe_send_report with a lambda (lambdas can't be async).
async def _async_true():
    return True
