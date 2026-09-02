"""Encrypt-at-rest helper for sensitive admin_config columns.

Stored values are tagged with a magic prefix (`SECRET_PREFIX`) so reads can
distinguish encrypted ciphertext from legacy plaintext rows. The prefix is
versioned so we can rotate the algorithm later without rewriting existing rows
all at once.

KEK lives in `ADMIN_CONFIG_SECRETS_KEY` (.env). In development with no key set
we deterministically derive one from `SECRET_KEY` so local runs stay simple;
production deployments must set it explicitly (enforced in `config.py`).
"""
from __future__ import annotations

import base64
import hashlib
import logging
from functools import lru_cache
from typing import Optional

from cryptography.fernet import Fernet, InvalidToken

from config import settings

logger = logging.getLogger(__name__)

SECRET_PREFIX = "fernet:v1:"


def _derive_dev_key(seed: str) -> bytes:
    """Stable Fernet key from a passphrase. Dev/local only — production
    deployments are required to set ADMIN_CONFIG_SECRETS_KEY explicitly."""
    digest = hashlib.sha256(seed.encode("utf-8")).digest()
    return base64.urlsafe_b64encode(digest)


@lru_cache(maxsize=1)
def _get_fernet() -> Fernet:
    raw = (settings.ADMIN_CONFIG_SECRETS_KEY or "").strip()
    if raw:
        # Accept either a urlsafe-base64 32-byte Fernet key, or any string we
        # can hash into one. Prefer the explicit Fernet form.
        try:
            return Fernet(raw.encode("utf-8"))
        except (ValueError, TypeError):
            return Fernet(_derive_dev_key(raw))
    if settings.ENVIRONMENT == "development":
        # Stable across restarts so dev DB rows decrypt after a reboot.
        return Fernet(_derive_dev_key(settings.SECRET_KEY or "catcoin-dev-secrets"))
    # config.py enforces non-empty in non-dev; this branch is unreachable, but
    # we keep it defensive in case ENVIRONMENT is set to a custom value.
    raise RuntimeError(
        "ADMIN_CONFIG_SECRETS_KEY is required in non-development environments"
    )


def encrypt_secret(plain: Optional[str]) -> Optional[str]:
    """Encrypt a string for at-rest storage. None / empty pass through."""
    if plain is None:
        return None
    if not isinstance(plain, str):
        plain = str(plain)
    if plain == "":
        return ""
    if plain.startswith(SECRET_PREFIX):
        # Already encrypted (e.g. admin pasted the stored value back). Don't
        # double-wrap — return as-is.
        return plain
    token = _get_fernet().encrypt(plain.encode("utf-8")).decode("utf-8")
    return SECRET_PREFIX + token


def decrypt_if_encrypted(stored: Optional[str]) -> Optional[str]:
    """Reverse of :func:`encrypt_secret`. Legacy plaintext (no prefix) is
    returned unchanged so existing rows keep working until the next admin
    save migrates them in-place."""
    if stored is None or stored == "":
        return stored
    if not isinstance(stored, str):
        return stored
    if not stored.startswith(SECRET_PREFIX):
        return stored
    token = stored[len(SECRET_PREFIX):]
    try:
        return _get_fernet().decrypt(token.encode("utf-8")).decode("utf-8")
    except InvalidToken:
        # Wrong key, tampered ciphertext, or corrupted row. Don't return the
        # ciphertext as if it were plaintext — fail closed.
        logger.error("admin_config secret failed Fernet decrypt; returning None")
        return None


# Columns whose admin-supplied values are encrypted at rest. Keep this list in
# sync with `routers/admin.py` writes and `schemas.AdminConfigResponse` reads.
SENSITIVE_ADMIN_CONFIG_FIELDS: tuple[str, ...] = (
    "discord_bot_token",
    "telegram_bot_token",
    "x_bearer_token",
    "x_consumer_key",
    "x_consumer_secret",
    "x_access_token",
    "x_access_token_secret",
    "x_client_id",
    "x_client_secret",
    "coin_explorer_api_key",
)
