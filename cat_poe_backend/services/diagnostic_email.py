"""Mail handler for client-side error reports.

Backs ``POST /v1/diagnostics/client-error``. Picks a target address (env first,
then admin_config), formats the report into an HTML email, and sends it via the
existing SMTP path used for verification / reset emails.

Design notes:

- **No-op when no target is configured.** Production environments that didn't
  opt in shouldn't fail or noisily warn. The endpoint still accepts the report.
- **No-op when SMTP isn't configured.** Mirrors EmailService's behaviour for
  development: log to stdout so devs can still see reports during local work.
- **Best-effort.** A failure to send is logged but never raised — the calling
  endpoint must not 5xx because mail is down.
- **Sanitisation is the caller's job.** This service trusts that the
  ``ClientErrorReport`` schema has already capped string lengths.
"""
from __future__ import annotations

import asyncio
import html
import logging
import os
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Any, Optional

from sqlalchemy.ext.asyncio import AsyncSession

import models
from config import settings

logger = logging.getLogger(__name__)


async def _resolve_target_email(db: AsyncSession) -> Optional[str]:
    """Env var wins; falls back to admin_config.error_report_email."""
    env_val = (settings.ERROR_REPORT_EMAIL or "").strip()
    if env_val:
        return env_val
    try:
        from services.session_manager import SessionManager

        config = await SessionManager.get_admin_config(db)
        attr = getattr(config, "error_report_email", None)
        if isinstance(attr, str) and attr.strip():
            return attr.strip()
    except Exception as exc:  # noqa: BLE001 — diagnostic path mustn't 5xx
        logger.warning("diagnostic_email: failed to read admin_config target: %s", exc)
    return None


def _format_subject(report: dict[str, Any]) -> str:
    fingerprint = report.get("fingerprint") or "unknown"
    app_version = report.get("app_version") or "unknown"
    return f"[Catcoin client error] {fingerprint} ({app_version})"


def _format_html(report: dict[str, Any]) -> str:
    def row(label: str, value: Any) -> str:
        return (
            "<tr>"
            f"<td style='padding:4px 12px 4px 0;color:#666;'>{html.escape(label)}</td>"
            f"<td style='padding:4px 0;'>{html.escape(str(value)) if value is not None else '—'}</td>"
            "</tr>"
        )

    breadcrumbs = report.get("breadcrumbs") or []
    bc_html = ""
    if breadcrumbs:
        items = "".join(f"<li>{html.escape(str(b))}</li>" for b in breadcrumbs)
        bc_html = f"<h3>Breadcrumbs (newest last)</h3><ol>{items}</ol>"

    return (
        "<html><body style='font-family:Arial, sans-serif;font-size:14px;'>"
        "<h2 style='margin-bottom:0;'>Catcoin client error report</h2>"
        "<p style='color:#666;margin-top:4px;'>"
        "Automatic report from the mobile / desktop client. Triggered when "
        "the client hit a non-recoverable state that operators should know about."
        "</p>"
        "<table style='border-collapse:collapse;'>"
        + row("Fingerprint", report.get("fingerprint"))
        + row("App version", report.get("app_version"))
        + row("Platform", report.get("platform"))
        + row("OS version", report.get("os_version"))
        + row("Locale", report.get("locale"))
        + row("Screen", report.get("screen"))
        + row("User ID", report.get("user_id"))
        + row("HTTP status", report.get("http_status"))
        + row("Error class", report.get("error_class"))
        + row("Error message", report.get("error_message"))
        + row("Occurred at (client clock)", report.get("occurred_at"))
        + "</table>"
        + bc_html
        + "<hr style='margin-top:24px;'>"
        + "<p style='color:#999;font-size:12px;'>"
        + "Catcoin diagnostics — POST /v1/diagnostics/client-error"
        + "</p>"
        + "</body></html>"
    )


async def maybe_send_report(report: dict[str, Any], db: AsyncSession) -> bool:
    """Send the email if a target is configured; return whether an email was sent.

    Always returns gracefully — callers can ignore the return value if they
    just want fire-and-forget behaviour.
    """
    target = await _resolve_target_email(db)
    if not target:
        logger.info(
            "diagnostic_email: no target configured; report fingerprint=%s "
            "from user_id=%s logged but not mailed",
            report.get("fingerprint"),
            report.get("user_id"),
        )
        return False

    smtp_server = os.getenv("SMTP_SERVER", "smtp.gmail.com")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    sender_email = os.getenv("SMTP_EMAIL", "noreply@example.com")
    sender_password = os.getenv("SMTP_PASSWORD", "")

    subject = _format_subject(report)
    body_html = _format_html(report)

    if not sender_password or os.getenv("ENVIRONMENT") == "development":
        # Match the existing EmailService dev-mode behaviour: print rather
        # than attempt a real SMTP handshake. This keeps local dev usable.
        print(f"\n{'=' * 60}")
        print("DIAG EMAIL (dev mode — would send to {})".format(target))
        print(f"Subject: {subject}")
        print(f"Body (truncated): {body_html[:200]}...")
        print(f"{'=' * 60}\n")
        return True

    message = MIMEMultipart("alternative")
    message["Subject"] = subject
    message["From"] = f"Catcoin Diagnostics <{sender_email}>"
    message["To"] = target
    message.attach(MIMEText(body_html, "html"))

    try:
        loop = asyncio.get_running_loop()

        def send_sync() -> None:
            with smtplib.SMTP(smtp_server, smtp_port, timeout=10) as server:
                server.starttls()
                server.login(sender_email, sender_password)
                server.sendmail(sender_email, target, message.as_string())

        await loop.run_in_executor(None, send_sync)
        logger.info(
            "diagnostic_email: sent fingerprint=%s to %s",
            report.get("fingerprint"),
            target,
        )
        return True
    except Exception as exc:  # noqa: BLE001
        logger.warning("diagnostic_email: send failed: %s", exc)
        return False
