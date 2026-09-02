from typing import Optional

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings. Use a `.env` file for local development (see `.env.example`)."""

    ENVIRONMENT: str = "development"

    DB_USER: str = "postgres"
    DB_PASSWORD: str = "postgres"
    DB_NAME: str = "catcoin_poe"
    DATABASE_URL: Optional[str] = None

    SECRET_KEY: str = ""
    # Fernet key (urlsafe-base64 32 bytes) used to encrypt sensitive
    # admin_config columns (bot tokens, X API keys, etc.) at rest.
    # In development a stable key is derived from SECRET_KEY when this is
    # unset; production deployments must set it explicitly.
    ADMIN_CONFIG_SECRETS_KEY: str = ""
    # Where client-side error reports (POST /v1/diagnostics/client-error)
    # are mailed. Wins over admin_config.error_report_email when both are
    # set. Leave blank to accept reports without emailing them.
    ERROR_REPORT_EMAIL: str = ""
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # In-process auth rate limits (per server instance). Use Redis/etc. for multi-worker.
    DISABLE_AUTH_RATE_LIMIT: bool = False
    AUTH_RL_SIGNUP_PER_HOUR_IP: int = 20
    AUTH_RL_LOGIN_PER_MINUTE_IP: int = 30
    AUTH_RL_FORGOT_PER_HOUR_IP: int = 10
    AUTH_RL_FORGOT_PER_HOUR_EMAIL: int = 5
    AUTH_RL_RESEND_PER_HOUR_IP: int = 15
    AUTH_RL_RESEND_PER_HOUR_EMAIL: int = 5
    AUTH_RL_VERIFY_PER_MINUTE_IP: int = 30
    AUTH_RL_RESET_PER_MINUTE_IP: int = 15

    DOCS_USER: str = "admin"
    DOCS_PASSWORD: str = ""

    # SMTP (loaded from the same `.env` as other settings; used by EmailService — do not rely on os.getenv alone).
    SMTP_SERVER: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_EMAIL: str = "noreply@example.com"
    SMTP_PASSWORD: str = ""
    # When false, connect with plain SMTP (no STARTTLS). Only for internal relays; Gmail requires TLS.
    SMTP_STARTTLS: bool = True
    # Socket timeout seconds (connect + SMTP dialogue).
    SMTP_TIMEOUT_SECONDS: int = 25

    @field_validator("SMTP_EMAIL", "SMTP_PASSWORD", mode="before")
    @classmethod
    def _strip_smtp_strings(cls, v):
        if isinstance(v, str):
            return v.strip()
        return v

    # When false, skip the asyncio daily loop in main.py; run `python -m jobs.referral_reconciliation` from cron.
    ENABLE_IN_PROCESS_REFERRAL_RECONCILIATION: bool = True

    # Drop email-unverified accounts after this many hours (zero balance / earnings only) so emails can sign up again.
    UNVERIFIED_USER_RETENTION_HOURS: int = 8
    # When false, run `python -m jobs.unverified_user_cleanup` from cron instead of the in-process loop.
    ENABLE_IN_PROCESS_UNVERIFIED_USER_CLEANUP: bool = True
    UNVERIFIED_CLEANUP_INTERVAL_SECONDS: int = 3600

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @model_validator(mode="after")
    def build_db_url_and_secrets(self):
        if not self.DATABASE_URL:
            self.DATABASE_URL = (
                f"postgresql+asyncpg://{self.DB_USER}:{self.DB_PASSWORD}"
                f"@localhost/{self.DB_NAME}"
            )

        if self.ENVIRONMENT == "development":
            if not self.SECRET_KEY:
                self.SECRET_KEY = "dev-only-not-for-production-or-shared-deployments"
            if not self.DOCS_PASSWORD:
                self.DOCS_PASSWORD = "dev-change-me-for-docs"
        else:
            if not self.SECRET_KEY or len(self.SECRET_KEY) < 24:
                raise ValueError(
                    "SECRET_KEY must be set to a strong value (24+ chars) "
                    "when ENVIRONMENT is not 'development'"
                )
            if not self.DOCS_PASSWORD:
                raise ValueError(
                    "DOCS_PASSWORD must be set when ENVIRONMENT is not 'development'"
                )
            if not self.ADMIN_CONFIG_SECRETS_KEY:
                raise ValueError(
                    "ADMIN_CONFIG_SECRETS_KEY must be set when ENVIRONMENT is "
                    "not 'development' (urlsafe-base64 32-byte Fernet key; "
                    "generate with `python -c \"from cryptography.fernet import "
                    "Fernet; print(Fernet.generate_key().decode())\"`)"
                )
        return self


settings = Settings()
