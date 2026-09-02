"""Resolve /invite/{code} destination from User-Agent (no client-side OS picker)."""
from __future__ import annotations

from typing import Any


def user_agent_is_android(ua_lower: str) -> bool:
    return "android" in ua_lower


def user_agent_is_ios(ua_lower: str) -> bool:
    """iOS / iPadOS / iOS WebKit browsers (Chrome, Firefox, Edge on iPhone)."""
    if user_agent_is_android(ua_lower):
        return False
    if "iphone" in ua_lower or "ipod" in ua_lower:
        return True
    if "ipad" in ua_lower or "ipados" in ua_lower:
        return True
    # Chrome / Firefox / Edge on iOS
    if "crios/" in ua_lower or "fxios/" in ua_lower or "edgios/" in ua_lower:
        return True
    return False


def _append_query(base: str, key: str, value: str) -> str:
    base = (base or "").strip()
    sep = "&" if "?" in base else "?"
    return f"{base}{sep}{key}={value}"


def google_play_url_with_install_referrer(play_listing_url: str, invite_code: str) -> str:
    """Play Install Referrer reads `referrer=` on the store URL (see app signup handling)."""
    base = (play_listing_url or "").strip() or (
        "https://play.google.com/store/apps/details?id=org.catcoin.cat"
    )
    return _append_query(base, "referrer", f"inv_{invite_code}")


def desktop_download_url_with_referral(windows_url: str, invite_code: str) -> str:
    base = (windows_url or "").strip() or "https://catcoin.in/download"
    return _append_query(base, "referral", invite_code)


def invite_destination_url(user_agent: str, invite_code: str, admin_config: Any) -> str:
    """
    Pick exactly one URL: Play (Android), App Store (iOS), or configured desktop/web fallback.
    """
    code = (invite_code or "").strip().upper()
    ua = (user_agent or "").lower()

    if user_agent_is_android(ua):
        play = getattr(admin_config, "update_url_android", None)
        return google_play_url_with_install_referrer(play or "", code)

    if user_agent_is_ios(ua):
        ios = (getattr(admin_config, "update_url_ios", None) or "").strip()
        return ios or "https://apps.apple.com/app/id123456789"

    win = getattr(admin_config, "update_url_windows", None)
    return desktop_download_url_with_referral(win or "", code)
