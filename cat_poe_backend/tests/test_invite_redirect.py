"""Invite link picks store from User-Agent (server-side)."""

from types import SimpleNamespace

import pytest

from services.invite_redirect import (
    invite_destination_url,
    user_agent_is_android,
    user_agent_is_ios,
)


@pytest.fixture
def config():
    return SimpleNamespace(
        update_url_android="https://play.google.com/store/apps/details?id=com.example.app",
        update_url_ios="https://apps.apple.com/app/id999888777",
        update_url_windows="https://download.example.com/start",
    )


def test_android_play_with_referrer(config):
    ua = "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36"
    url = invite_destination_url(ua, "TREFabc", config)
    assert "play.google.com" in url
    assert "referrer=inv_TREFABC" in url


def test_ios_app_store(config):
    ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"
    url = invite_destination_url(ua, "TREFabc", config)
    assert url == "https://apps.apple.com/app/id999888777"


def test_chrome_on_ios(config):
    ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/120.0.6099.119 Mobile/15E148 Safari/604.1"
    assert user_agent_is_ios(ua.lower())
    assert not user_agent_is_android(ua.lower())
    url = invite_destination_url(ua, "X1", config)
    assert "apps.apple.com" in url


def test_desktop_fallback_query(config):
    ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    url = invite_destination_url(ua, "REF99", config)
    assert url.startswith("https://download.example.com/start")
    assert "referral=REF99" in url


def test_android_not_ios():
    ua = "Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36"
    assert user_agent_is_android(ua.lower())
    assert not user_agent_is_ios(ua.lower())
