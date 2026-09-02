from __future__ import annotations

from typing import Any, Optional, List, Type, Dict
from datetime import datetime
from enum import Enum
import uuid
import re

from pydantic import BaseModel, ConfigDict, field_serializer, field_validator, EmailStr, Field, model_validator
from pydantic_core import PydanticUndefined


def _orm_admin_config_to_dict(data: Any) -> Any:
    """SQLAlchemy rows can have NULL where Column(default=...) was not applied at insert; mirror those defaults."""
    import models
    from sqlalchemy import inspect as sa_inspect

    if not isinstance(data, models.AdminConfig):
        return data
    mapper = sa_inspect(data).mapper
    out: dict[str, Any] = {}
    for col in mapper.columns:
        val = getattr(data, col.key)
        if val is None and col.default is not None:
            arg = getattr(col.default, "arg", None)
            if arg is not None:
                val = arg() if callable(arg) else arg
        out[col.key] = val
    return out


def _apply_pydantic_field_defaults(data: dict[str, Any], model_cls: Type[BaseModel]) -> dict[str, Any]:
    """Pydantic v2 does not substitute Field defaults when the input explicitly contains None."""
    for name, finfo in model_cls.model_fields.items():
        if data.get(name) is not None:
            continue
        if finfo.default is not PydanticUndefined:
            data[name] = finfo.default
        elif finfo.default_factory is not None:
            data[name] = finfo.default_factory()
    return data


def _admin_config_response_before(model_cls: Type[BaseModel], data: Any) -> Any:
    data = _orm_admin_config_to_dict(data)
    if isinstance(data, dict):
        data = _apply_pydantic_field_defaults(data, model_cls)
        # Sensitive fields are stored encrypted with a magic prefix; decrypt
        # here so the admin GET response carries plaintext (admin UI shows the
        # current value). PublicAdminConfigResponse does not include any of
        # these columns, so this helper is safe for both response models.
        from services.secret_crypto import (
            decrypt_if_encrypted,
            SENSITIVE_ADMIN_CONFIG_FIELDS,
        )
        for field in SENSITIVE_ADMIN_CONFIG_FIELDS:
            if field in data and data[field]:
                data[field] = decrypt_if_encrypted(data[field])
    return data


def _coerce_max_active_referrers(v: Any) -> Any:
    """Count of referrers is always an integer; JSON/clients may send whole floats."""
    if v is None:
        return v
    if isinstance(v, bool):
        raise ValueError("max_active_referrers must be an integer")
    if isinstance(v, int):
        return v
    if isinstance(v, float):
        return int(round(v))
    if isinstance(v, str):
        s = v.strip()
        if s.removeprefix("-").isdigit():
            return int(s)
    return v


def _validate_int_list_json(v: Any, *, field: str, min_value: int = 1, max_value: int = 86_400, max_len: int = 32) -> Any:
    """Decode a JSON string holding a non-empty list of positive ints.

    These columns are stored as TEXT for legacy reasons; readers do `json.loads`
    and crash/fall back on bad input. Validate on the way in so operators see
    422 instead of silent runtime failures.
    """
    if v is None:
        return None
    if not isinstance(v, str):
        raise ValueError(f"{field} must be a JSON string")
    s = v.strip()
    if s == "":
        return None
    try:
        import json as _json
        parsed = _json.loads(s)
    except Exception as exc:
        raise ValueError(f"{field} is not valid JSON") from exc
    if not isinstance(parsed, list) or not parsed:
        raise ValueError(f"{field} must be a non-empty JSON array")
    if len(parsed) > max_len:
        raise ValueError(f"{field}: too many entries (max {max_len})")
    out: List[int] = []
    for i, n in enumerate(parsed):
        if isinstance(n, bool) or not isinstance(n, int):
            raise ValueError(f"{field}[{i}] must be an integer")
        if n < min_value or n > max_value:
            raise ValueError(f"{field}[{i}] out of range [{min_value}, {max_value}]")
        out.append(n)
    import json as _json
    return _json.dumps(out)


def _validate_object_json(v: Any, *, field: str, max_bytes: int = 32_768) -> Any:
    """Decode a JSON string holding a top-level object. Re-serializes canonically."""
    if v is None:
        return None
    if not isinstance(v, str):
        raise ValueError(f"{field} must be a JSON string")
    s = v.strip()
    if s == "":
        return None
    if len(s.encode("utf-8")) > max_bytes:
        raise ValueError(f"{field}: payload too large")
    try:
        import json as _json
        parsed = _json.loads(s)
    except Exception as exc:
        raise ValueError(f"{field} is not valid JSON") from exc
    if not isinstance(parsed, dict):
        raise ValueError(f"{field} must be a JSON object")
    import json as _json
    return _json.dumps(parsed)


def _validate_http_url(v: Any) -> Any:
    """Allow only http(s) URLs with a host. Rejects javascript:, file:, intent:, etc."""
    if v is None:
        return None
    if not isinstance(v, str):
        raise ValueError("must be a string URL")
    s = v.strip()
    if s == "":
        return None
    if len(s) > 2048:
        raise ValueError("URL too long")
    try:
        from urllib.parse import urlparse
        parsed = urlparse(s)
    except Exception as exc:
        raise ValueError("invalid URL") from exc
    if parsed.scheme not in ("http", "https"):
        raise ValueError("URL scheme must be http or https")
    if not parsed.netloc:
        raise ValueError("URL must include a host")
    return s


_WHATS_NEW_MAX_ENTRIES = 100
_WHATS_NEW_MAX_NOTES_PER_LOCALE = 50
_WHATS_NEW_MAX_NOTE_LEN = 1000
_WHATS_NEW_MAX_DATE_LABEL_LEN = 64
_WHATS_NEW_MAX_VERSION_LEN = 32
_WHATS_NEW_MAX_TRANSLATION_LANGS = 40
_WHATS_NEW_LANG_RE = re.compile(r"^[a-z]{2,3}(?:[_-][A-Za-z0-9]+)*$")


def _validate_whats_new_translation_block(block: Any, *, where: str) -> Dict[str, Any]:
    if not isinstance(block, dict):
        raise ValueError(f"{where}: translation block must be an object")
    out: Dict[str, Any] = {}
    dl = block.get("date_label")
    if dl is not None:
        if not isinstance(dl, str):
            raise ValueError(f"{where}.date_label: must be a string")
        if len(dl) > _WHATS_NEW_MAX_DATE_LABEL_LEN:
            raise ValueError(f"{where}.date_label: too long")
        out["date_label"] = dl
    notes = block.get("notes")
    if notes is not None:
        if not isinstance(notes, list):
            raise ValueError(f"{where}.notes: must be a list of strings")
        if len(notes) > _WHATS_NEW_MAX_NOTES_PER_LOCALE:
            raise ValueError(f"{where}.notes: too many entries")
        clean: List[str] = []
        for i, n in enumerate(notes):
            if not isinstance(n, str):
                raise ValueError(f"{where}.notes[{i}]: must be a string")
            if len(n) > _WHATS_NEW_MAX_NOTE_LEN:
                raise ValueError(f"{where}.notes[{i}]: too long")
            clean.append(n)
        out["notes"] = clean
    return out


def _validate_whats_new_json(v: Any) -> Any:
    """Strict shape check for admin-supplied What's New release entries.

    Each entry: {version: str, [date_label: str], [notes: [str]],
                 [translations: {<lang>: {date_label, notes}}]}.
    """
    if v is None:
        return None
    if not isinstance(v, list):
        raise ValueError("whats_new_json must be a list")
    if len(v) > _WHATS_NEW_MAX_ENTRIES:
        raise ValueError("whats_new_json: too many entries")
    cleaned: List[Dict[str, Any]] = []
    for idx, entry in enumerate(v):
        if not isinstance(entry, dict):
            raise ValueError(f"whats_new_json[{idx}]: entry must be an object")
        version = entry.get("version")
        if not isinstance(version, str) or not version.strip():
            raise ValueError(f"whats_new_json[{idx}].version: required string")
        if len(version) > _WHATS_NEW_MAX_VERSION_LEN:
            raise ValueError(f"whats_new_json[{idx}].version: too long")
        out: Dict[str, Any] = {"version": version}

        legacy = _validate_whats_new_translation_block(
            {"date_label": entry.get("date_label"), "notes": entry.get("notes")},
            where=f"whats_new_json[{idx}]",
        ) if (entry.get("date_label") is not None or entry.get("notes") is not None) else {}
        out.update(legacy)

        translations = entry.get("translations")
        if translations is not None:
            if not isinstance(translations, dict):
                raise ValueError(f"whats_new_json[{idx}].translations: must be an object")
            if len(translations) > _WHATS_NEW_MAX_TRANSLATION_LANGS:
                raise ValueError(f"whats_new_json[{idx}].translations: too many locales")
            tr_out: Dict[str, Dict[str, Any]] = {}
            for lk, blk in translations.items():
                if not isinstance(lk, str) or not _WHATS_NEW_LANG_RE.match(lk):
                    raise ValueError(
                        f"whats_new_json[{idx}].translations: invalid language key {lk!r}"
                    )
                tr_out[lk] = _validate_whats_new_translation_block(
                    blk, where=f"whats_new_json[{idx}].translations[{lk}]"
                )
            out["translations"] = tr_out

        # Reject unknown top-level keys to avoid quietly-stored junk.
        allowed = {"version", "date_label", "notes", "translations"}
        extra = set(entry.keys()) - allowed
        if extra:
            raise ValueError(
                f"whats_new_json[{idx}]: unknown keys {sorted(extra)}"
            )

        cleaned.append(out)
    return cleaned


class UserBase(BaseModel):
    username: str

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    referred_by: Optional[str] = None  # Referral code used during signup


class SignupAckResponse(BaseModel):
    """Public signup response (success or duplicate email — same shape)."""
    message: str


class UserResponse(UserBase):
    id: uuid.UUID
    email: str
    display_name: Optional[str] = None
    referral_code: str
    referred_by: Optional[str] = None  # Referral code of referrer
    referred_by_display_name: Optional[str] = None  # Referrer's display name for UI
    balance: float
    country: Optional[str] = "US"
    country_source: Optional[str] = None
    email_verified: bool
    created_at: datetime
    is_admin: bool = False
    discord_id: Optional[str] = None
    discord_id_verified: bool = False
    discord_id_locked: bool = False
    telegram_id: Optional[str] = None
    telegram_id_verified: bool = False
    telegram_id_locked: bool = False
    x_id: Optional[str] = None
    x_id_verified: bool = False
    x_id_locked: bool = False
    facebook_id: Optional[str] = None
    facebook_id_verified: bool = False
    facebook_id_locked: bool = False
    whatsapp_id: Optional[str] = None
    whatsapp_id_verified: bool = False
    whatsapp_id_locked: bool = False
    is_suspicious: bool = False
    ip_address: Optional[str] = None
    device_id: Optional[str] = None

    # Google Play Age Signals (Texas SB 2420; Play Age Signals API v0.0.3).
    # Values mirror the platform enum verbatim:
    #   null / "not_checked" / "not_required" / "verified" / "not_verified" / "pending"
    age_signal_status: Optional[str] = None
    age_signal_checked_at: Optional[datetime] = None

    # Withdrawal Permissions
    can_withdraw_mining: bool = True
    can_withdraw_referrals: bool = True
    can_withdraw_missions: bool = True
    can_withdraw_games: bool = True
    can_withdraw_game_boosts: bool = False
    showcase_badge_ids: List[str] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)

    @field_validator("showcase_badge_ids", mode="before")
    @classmethod
    def _normalize_showcase(cls, v):
        if v is None:
            return []
        if isinstance(v, list):
            return [str(x) for x in v]
        return []
    
    @field_serializer('id')
    def serialize_uuid(self, v):
        return str(v)

class UserBadgeResponse(BaseModel):
    id: uuid.UUID
    badge_type: str
    description: Optional[str] = None
    awarded_at: datetime
    period_year: Optional[int] = None
    period_month: Optional[int] = None
    podium_rank: Optional[int] = None
    award_scope: Optional[str] = None
    region_code: Optional[str] = None
    game_type: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

    @field_serializer('id')
    def serialize_uuid(self, v):
        return str(v)


class AwardMonthlyPodiumRequest(BaseModel):
    """Defaults to the most recently completed calendar month (UTC)."""
    year: Optional[int] = None
    month: Optional[int] = None  # 1–12


class AwardMonthlyPodiumResponse(BaseModel):
    period_year: int
    period_month: int
    awarded: List[uuid.UUID]
    skipped_existing: List[uuid.UUID]
    regional_awarded_count: int = 0
    regional_skipped_count: int = 0
    game_awarded_count: int = 0
    game_skipped_count: int = 0
    message: str


class UpdateShowcaseBadgesRequest(BaseModel):
    badge_ids: List[uuid.UUID]  # display order; max 6 enforced server-side


class PodiumPreviewEntry(BaseModel):
    id: str
    username: str
    display_name: Optional[str] = None
    country: str = "US"
    balance: float
    rank: int


class PreviousMonthGamePodium(BaseModel):
    game_type: str
    leaders: List[PodiumPreviewEntry]


class PreviousMonthSummaryResponse(BaseModel):
    period_year: int
    period_month: int
    global_leaders: List[PodiumPreviewEntry]
    regional_leaders: List[PodiumPreviewEntry]
    games: List[PreviousMonthGamePodium]

class SuspiciousActivityBase(BaseModel):
    activity_type: str
    evidence: str

class SuspiciousActivityCreate(SuspiciousActivityBase):
    user_id: uuid.UUID
    related_user_id: Optional[uuid.UUID] = None

class SuspiciousActivityResponse(SuspiciousActivityBase):
    id: uuid.UUID
    user_id: uuid.UUID
    related_user_id: Optional[uuid.UUID] = None
    related_user_username: Optional[str] = None
    related_user_email: Optional[str] = None
    related_user_ip: Optional[str] = None
    related_user_device_id: Optional[str] = None
    related_user_discord_id: Optional[str] = None
    related_user_telegram_id: Optional[str] = None
    related_user_x_id: Optional[str] = None
    is_resolved: bool = False
    detected_at: datetime
    
    model_config = ConfigDict(from_attributes=True)
    
    @field_serializer('id', 'user_id', 'related_user_id')
    def serialize_uuid(self, v):
        return str(v) if v else None

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class RefreshTokenRequest(BaseModel):
    refresh_token: str

class TokenData(BaseModel):
    username: Optional[str] = None

# Email verification schemas
class VerifyEmailRequest(BaseModel):
    email: str
    code: str

class ResendCodeRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str

class UpdateProfileRequest(BaseModel):
    display_name: Optional[str] = None
    discord_id: Optional[str] = None
    telegram_id: Optional[str] = None
    x_id: Optional[str] = None
    facebook_id: Optional[str] = None
    whatsapp_id: Optional[str] = None
    country: Optional[str] = None
    country_source: Optional[str] = None
    confirm_social_reward_revocation: bool = False

_AGE_SIGNAL_ALLOWED = frozenset(
    {"not_checked", "not_required", "verified", "not_verified", "pending"}
)


class AdminUserUpdate(BaseModel):
    display_name: Optional[str] = None
    email_verified: Optional[bool] = None
    is_suspicious: Optional[bool] = None
    can_withdraw_mining: Optional[bool] = None
    can_withdraw_referrals: Optional[bool] = None
    can_withdraw_missions: Optional[bool] = None
    can_withdraw_games: Optional[bool] = None
    can_withdraw_game_boosts: Optional[bool] = None
    # Admin override for the Google Play Age Signals status. Submit one of
    # the enum strings, an empty string to clear, or omit to leave unchanged.
    age_signal_status: Optional[str] = None

    @field_validator("age_signal_status", mode="before")
    @classmethod
    def _validate_age_signal_status(cls, v: Any) -> Any:
        if v is None:
            return None
        if not isinstance(v, str):
            raise ValueError("age_signal_status must be a string")
        s = v.strip()
        if s == "":
            return ""  # treated by the PUT handler as "clear"
        if s not in _AGE_SIGNAL_ALLOWED:
            raise ValueError(
                "age_signal_status must be one of "
                f"{sorted(_AGE_SIGNAL_ALLOWED)} (got {s!r})"
            )
        return s

class AdminUserActivitySummary(BaseModel):
    """
    Engagement breakdown for the **current search / suspicious / role filters only** —
    not the activity_status filter. ``inactive_users`` uses ``last_active_at`` (app touch),
    which is unrelated to whether a user is actively **mining** (referral page semantics).
    """

    total_users: int
    active_users: int
    inactive_users: int


class AdminUserListResponse(BaseModel):
    users: List[UserResponse]
    total_count: int
    has_more: bool
    activity_summary: Optional[AdminUserActivitySummary] = None


class BulkPingStatsResponse(BaseModel):
    """Stats for in-app ping row creation (not push delivery)."""

    total_targets: int = Field(
        ...,
        description="Recipients considered in this request (after de-duplicating IDs).",
    )
    pinged: int = Field(..., description="New in-app ping rows inserted.")
    skipped: int = Field(
        ...,
        description="Recipients skipped because a row already exists in the dedupe lookback window.",
    )
    failed: int = Field(
        ...,
        description="Recipients not pinged due to a database error on commit (rare; whole batch rolls back).",
    )

class UpdateReferredByRequest(BaseModel):
    referral_code: str

class ResetSocialIdRequest(BaseModel):
    platform: str # 'discord', 'telegram', 'x', 'facebook', 'whatsapp'

class MiningStatus(str, Enum):
    ACTIVE = "ACTIVE"
    COMPLETED = "COMPLETED"

class MiningSessionBase(BaseModel):
    pass

class MiningSessionCreate(MiningSessionBase):
    pass

class MiningSessionResponse(MiningSessionBase):
    id: uuid.UUID
    user_id: uuid.UUID
    start_time: datetime
    end_time: datetime
    status: MiningStatus

    model_config = ConfigDict(from_attributes=True)
    
    @field_serializer('id', 'user_id')
    def serialize_uuid(self, v):
        return str(v)

class StatsResponse(BaseModel):
    balance: float
    yield_percentage: float
    active_session: Optional[MiningSessionResponse] = None

class MissionType(str, Enum):
    AD = "AD"
    SOCIAL = "SOCIAL"
    OTHER = "OTHER"

class MissionBase(BaseModel):
    code: str
    title: str
    description: Optional[str] = None
    link: Optional[str] = None
    icon: Optional[str] = None
    type: MissionType
    reward_amount: float
    is_active: bool = True
    expires_at: Optional[datetime] = None
    prerequisite_id: Optional[uuid.UUID] = None # ID of mission that must be completed first

class MissionCreate(BaseModel):
    code: Optional[str] = None
    title: str
    description: Optional[str] = None
    link: Optional[str] = None
    icon: Optional[str] = None
    type: MissionType
    reward_amount: float
    is_active: bool = True
    expires_at: Optional[datetime] = None
    prerequisite_id: Optional[uuid.UUID] = None

class MissionUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    link: Optional[str] = None
    icon: Optional[str] = None
    type: Optional[MissionType] = None
    reward_amount: Optional[float] = None
    is_active: Optional[bool] = None
    expires_at: Optional[datetime] = None
    prerequisite_id: Optional[uuid.UUID] = None

class MissionResponse(MissionBase):
    id: uuid.UUID
    is_completed: bool = False
    status: Optional[str] = None # PENDING, COMPLETED, REJECTED
    created_at: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)
    
    @field_serializer('id', 'prerequisite_id')
    def serialize_uuid(self, v):
        return str(v) if v else None

class MissionComplete(BaseModel):
    code: str
    verification_data: Optional[str] = None

class WalletBase(BaseModel):
    catcoin_address: str
    is_primary: bool = False
    source: Optional[str] = "MANUAL" # GENERATED, IMPORTED, MANUAL

    @field_validator('catcoin_address')
    @classmethod
    def validate_address(cls, v: str) -> str:
        v = v.strip()
        # EVM Regex (0x + 40 hex)
        evm_pattern = re.compile(r'^0x[a-fA-F0-9]{40}$')
        # Solana Regex (Base58 characters, length 32-44)
        sol_pattern = re.compile(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$')
        # Catcoin Legacy (Base58Check, Starts with '9', ~34 chars)
        # 0x15 (21) version byte leads to '9' prefix in Base58 checking. 
        # Length usually 33-34 chars.
        cat_legacy_pattern = re.compile(r'^9[1-9A-HJ-NP-Za-km-z]{25,34}$')

        if not (evm_pattern.match(v) or sol_pattern.match(v) or cat_legacy_pattern.match(v)):
             raise ValueError('Invalid wallet address. Must be a valid EVM (0x...), Solana, or Catcoin (starts with 9) address.')
        return v

class WalletCreate(WalletBase):
    pass

class WalletResponse(WalletBase):
    id: uuid.UUID
    user_id: uuid.UUID

    model_config = ConfigDict(from_attributes=True)
    
    @field_serializer('id', 'user_id')
    def serialize_uuid(self, v):
        return str(v)

class PayoutResponse(BaseModel):
    id: uuid.UUID
    amount: float
    status: str
    date: datetime
    
    @field_serializer('id')
    def serialize_uuid(self, v):
        return str(v)

# Addon Schemas for Prompts 10-16

class SessionType(str, Enum):
    BASE = "BASE"
    REFERRAL_BOOST = "REFERRAL_BOOST"
    GAME_BOOST = "GAME_BOOST"

class TimeBoostSlotResponse(BaseModel):
    hours: int
    cooldown_until: Optional[datetime] = None
    active: bool = True


class ActiveSessionResponse(BaseModel):
    id: uuid.UUID
    session_type: SessionType
    mining_for: Optional[uuid.UUID] = None
    yield_percentage: float
    start_time: datetime
    end_time: datetime
    total_earned: float
    reward_y: int = 0
    reward_t: int = 1
    time_boost_slots: Optional[List[TimeBoostSlotResponse]] = None

    model_config = ConfigDict(from_attributes=True)

    @field_serializer('id', 'mining_for')
    def serialize_uuid(self, v):
        return str(v) if v else None

class ReferralInfo(BaseModel):
    referral_id: uuid.UUID
    referral_username: str
    referral_display_name: Optional[str] = None  # Display name for UI
    is_active: bool
    last_active_at: datetime
    can_boost: bool
    active_boost_session_id: Optional[uuid.UUID] = None
    
    @field_serializer('referral_id', 'active_boost_session_id')
    def serialize_uuid(self, v):
        return str(v) if v else None

class RewardType(str, Enum):
    MINING_BASE = "MINING_BASE"
    MINING_REFERRAL_BOOST = "MINING_REFERRAL_BOOST"
    GAME_BOOST = "GAME_BOOST"
    SOCIAL_FACEBOOK = "SOCIAL_FACEBOOK"
    SOCIAL_X = "SOCIAL_X"
    SOCIAL_DISCORD = "SOCIAL_DISCORD"
    SOCIAL_TELEGRAM = "SOCIAL_TELEGRAM"
    MISSION_COMPLETION = "MISSION_COMPLETION"
    REFERRAL_SIGNUP_BONUS = "REFERRAL_SIGNUP_BONUS"
    AIRDROP = "AIRDROP"
    WITHDRAWAL = "WITHDRAWAL"
    GAME_REWARD = "GAME_REWARD"
    REFERRAL_BONUS = "REFERRAL_BONUS"

class EarningsBreakdownResponse(BaseModel):
    MINING_BASE: float = 0.0
    MINING_REFERRAL_BOOST: float = 0.0
    GAME_BOOST: float = 0.0
    SOCIAL_FACEBOOK: float = 0.0
    SOCIAL_X: float = 0.0
    SOCIAL_DISCORD: float = 0.0
    SOCIAL_TELEGRAM: float = 0.0
    MISSION_COMPLETION: float = 0.0
    REFERRAL_SIGNUP_BONUS: float = 0.0
    AIRDROP: float = 0.0
    WITHDRAWAL: float = 0.0
    GAME_REWARD: float = 0.0
    REFERRAL_BONUS: float = 0.0

    model_config = ConfigDict(extra="ignore")

class WalletSummaryResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    catcoin_address: str
    is_primary: bool
    source: str
    
    model_config = ConfigDict(from_attributes=True)
    
    @field_serializer('id', 'user_id')
    def serialize_uuid(self, v):
        return str(v)

class BalanceDetailsResponse(BaseModel):
    primary_wallet: Optional[WalletSummaryResponse] = None
    earnings_breakdown: EarningsBreakdownResponse
    withdrawal_permissions: dict # e.g. {"mining": true, "games": true, ...}
    total_balance: float
    game_withdrawal_threshold: float = 100000000.0 # 1 CAT (10^8 Catoshi)
    global_withdrawal_enabled: bool = True

class EarningsLedgerEntryResponse(BaseModel):
    id: uuid.UUID
    amount: float
    reward_type: str
    description: Optional[str] = None
    created_at: datetime
    is_verified: bool
    
    model_config = ConfigDict(from_attributes=True)
    
    @field_serializer('id')
    def serialize_uuid(self, v):
        return str(v)

class EnhancedStatsResponse(BaseModel):
    balance: float
    yield_percentage: float
    referral_boost_percentage: float = 0.0 # Explicit boost component
    active_sessions: List[ActiveSessionResponse] = []
    earnings_breakdown: EarningsBreakdownResponse
    total_verified_earnings: float
    total_unverified_earnings: float
    available_referrals: List[ReferralInfo] = []

class LeaderboardSortBy(str, Enum):
    BALANCE = "BALANCE"
    TOTAL_EARNINGS = "TOTAL_EARNINGS"


class WhatsNewReleaseItem(BaseModel):
    version: str
    date_label: str
    notes: List[str] = Field(default_factory=list)


class WhatsNewResponse(BaseModel):
    releases: List[WhatsNewReleaseItem] = Field(default_factory=list)


class AdminConfigResponse(BaseModel):
    global_withdrawal_enabled: bool
    ad_required_for_mining_start: bool
    ad_required_for_speed_boost: bool
    ad_required_for_time_boost: bool
    time_boost_duration_seconds: int
    speed_boost_per_referral: float
    android_ad_unit_id: Optional[str] = None
    ios_ad_unit_id: Optional[str] = None
    app_ads_content: Optional[str] = None
    game_ads_enabled: bool = False
    base_hashrate: float
    base_mining_duration_minutes: int
    max_mining_duration_minutes: int
    time_extension_slots: str
    max_referral_boost_hashrate: float
    discord_bot_token: Optional[str] = None
    discord_guild_id: Optional[str] = None
    telegram_bot_token: Optional[str] = None
    telegram_chat_id: Optional[str] = None
    x_bearer_token: Optional[str] = None
    x_community_username: Optional[str] = None
    x_consumer_key: Optional[str] = None
    x_consumer_secret: Optional[str] = None
    x_access_token: Optional[str] = None
    x_access_token_secret: Optional[str] = None
    x_client_id: Optional[str] = None
    x_client_secret: Optional[str] = None
    enable_verification_release: bool = True
    enable_verification_debug: bool = True
    verification_backoff_delays: str = "[120, 180, 300, 420, 600]"
    coin_explorer_api_key: Optional[str] = None
    enable_wallet_holding_days: bool = True
    enable_profile_picture: bool = False
    use_manual_cat_price: bool = False
    manual_cat_price_usdt: int = 50000
    coingecko_coin_id: str = "catcoins"
    catoshi_yield_percentage: float = 100.0
    referral_boost_percentage: float = 10.0
    max_active_referrers: int = 10
    referral_signup_bonus_referee_amount: float = 100.0
    referral_signup_bonus_referrer_amount: float = 50.0
    referral_milestone_bonus_catoshi: int = 10_000_000
    leaderboard_sort_by: LeaderboardSortBy = LeaderboardSortBy.BALANCE
    game_boost_config: Optional[str] = None
    game_reward_config: Optional[str] = None

    # Game Module Configuration
    is_runner_game_visible: bool = True
    is_miner_game_visible: bool = True
    is_tictactoe_game_visible: bool = True
    is_sudoku_game_visible: bool = True
    is_collage_game_visible: bool = True
    is_arrow_game_visible: bool = True
    is_twenty48_game_visible: bool = True
    is_tile_swap_game_visible: bool = True
    # Optional. When set (here or via the ERROR_REPORT_EMAIL env var) the
    # diagnostics endpoint mails client error reports here.
    error_report_email: Optional[str] = None

    global_push_message: Optional[str] = None
    global_push_messages: Optional[Dict[str, str]] = None

    # Version Control
    # Version Control
    latest_version_android: Optional[str] = "1.0.0"
    min_version_android: Optional[str] = "1.0.0"
    update_url_android: Optional[str] = None
    
    latest_version_ios: Optional[str] = "1.0.0"
    min_version_ios: Optional[str] = "1.0.0"
    update_url_ios: Optional[str] = None
    
    latest_version_windows: Optional[str] = "1.0.0"
    min_version_windows: Optional[str] = "1.0.0"
    update_url_windows: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="before")
    @classmethod
    def _fill_nulls_from_db(cls, data: Any) -> Any:
        return _admin_config_response_before(cls, data)

    @field_validator("global_push_messages", mode="before")
    @classmethod
    def _normalize_global_push_messages(cls, v: Any) -> Any:
        if v is None:
            return None
        if not isinstance(v, dict):
            return None
        out: Dict[str, str] = {}
        for key, val in v.items():
            if key is None or val is None:
                continue
            k = str(key).strip().split("-")[0].split("_")[0].lower()
            if isinstance(val, str):
                out[k] = val
            else:
                out[k] = str(val)
        return out or None

    @field_validator("max_active_referrers", mode="before")
    @classmethod
    def _max_active_referrers_as_int(cls, v: Any) -> Any:
        return _coerce_max_active_referrers(v)


class PublicAdminConfigResponse(BaseModel):
    """Subset of admin config safe for unauthenticated mobile clients (no bot/API secrets)."""

    global_withdrawal_enabled: bool
    ad_required_for_mining_start: bool
    ad_required_for_speed_boost: bool
    ad_required_for_time_boost: bool
    time_boost_duration_seconds: int
    speed_boost_per_referral: float
    android_ad_unit_id: Optional[str] = None
    ios_ad_unit_id: Optional[str] = None
    app_ads_content: Optional[str] = None
    game_ads_enabled: bool = False
    base_hashrate: float
    base_mining_duration_minutes: int
    max_mining_duration_minutes: int
    time_extension_slots: str
    max_referral_boost_hashrate: float
    discord_guild_id: Optional[str] = None
    telegram_chat_id: Optional[str] = None
    x_community_username: Optional[str] = None
    enable_verification_release: bool = True
    enable_verification_debug: bool = True
    verification_backoff_delays: str = "[120, 180, 300, 420, 600]"
    enable_wallet_holding_days: bool = True
    enable_profile_picture: bool = False
    use_manual_cat_price: bool = False
    manual_cat_price_usdt: int = 50000
    coingecko_coin_id: str = "catcoins"
    catoshi_yield_percentage: float = 100.0
    referral_boost_percentage: float = 10.0
    max_active_referrers: int = 10
    referral_signup_bonus_referee_amount: float = 100.0
    referral_milestone_bonus_catoshi: int = 10_000_000
    leaderboard_sort_by: LeaderboardSortBy = LeaderboardSortBy.BALANCE
    game_boost_config: Optional[str] = None
    game_reward_config: Optional[str] = None
    is_runner_game_visible: bool = True
    is_miner_game_visible: bool = True
    is_tictactoe_game_visible: bool = True
    is_sudoku_game_visible: bool = True
    is_collage_game_visible: bool = True
    is_arrow_game_visible: bool = True
    is_twenty48_game_visible: bool = True
    is_tile_swap_game_visible: bool = True
    error_report_email: Optional[str] = None
    global_push_message: Optional[str] = None
    latest_version_android: Optional[str] = "1.0.0"
    min_version_android: Optional[str] = "1.0.0"
    update_url_android: Optional[str] = None
    latest_version_ios: Optional[str] = "1.0.0"
    min_version_ios: Optional[str] = "1.0.0"
    update_url_ios: Optional[str] = None
    latest_version_windows: Optional[str] = "1.0.0"
    min_version_windows: Optional[str] = "1.0.0"
    update_url_windows: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="before")
    @classmethod
    def _fill_nulls_from_db(cls, data: Any) -> Any:
        return _admin_config_response_before(cls, data)

    @field_validator("max_active_referrers", mode="before")
    @classmethod
    def _max_active_referrers_as_int(cls, v: Any) -> Any:
        return _coerce_max_active_referrers(v)


class AdminConfigUpdate(BaseModel):
    global_withdrawal_enabled: Optional[bool] = None
    ad_required_for_mining_start: Optional[bool] = None
    ad_required_for_speed_boost: Optional[bool] = None
    ad_required_for_time_boost: Optional[bool] = None
    game_ads_enabled: Optional[bool] = None
    time_boost_duration_seconds: Optional[int] = None
    speed_boost_per_referral: Optional[float] = None
    base_hashrate: Optional[float] = None
    android_ad_unit_id: Optional[str] = None
    ios_ad_unit_id: Optional[str] = None
    app_ads_content: Optional[str] = None
    base_mining_duration_minutes: Optional[int] = None
    max_mining_duration_minutes: Optional[int] = None
    time_extension_slots: Optional[str] = None
    game_boost_config: Optional[str] = None
    game_reward_config: Optional[str] = None
    max_referral_boost_hashrate: Optional[float] = None
    discord_bot_token: Optional[str] = None
    discord_guild_id: Optional[str] = None
    telegram_bot_token: Optional[str] = None
    telegram_chat_id: Optional[str] = None
    x_bearer_token: Optional[str] = None
    x_community_username: Optional[str] = None
    x_consumer_key: Optional[str] = None
    x_consumer_secret: Optional[str] = None
    x_access_token: Optional[str] = None
    x_access_token_secret: Optional[str] = None
    x_client_id: Optional[str] = None
    x_client_secret: Optional[str] = None
    enable_verification_release: Optional[bool] = None
    enable_verification_debug: Optional[bool] = None
    verification_backoff_delays: Optional[str] = None
    coin_explorer_api_key: Optional[str] = None
    enable_wallet_holding_days: Optional[bool] = None
    enable_profile_picture: Optional[bool] = None
    use_manual_cat_price: Optional[bool] = None
    manual_cat_price_usdt: Optional[int] = None
    coingecko_coin_id: Optional[str] = None
    catoshi_yield_percentage: Optional[float] = None
    referral_boost_percentage: Optional[float] = None
    max_active_referrers: Optional[int] = None
    referral_signup_bonus_referee_amount: Optional[float] = None
    referral_signup_bonus_referrer_amount: Optional[float] = None
    referral_milestone_bonus_catoshi: Optional[int] = None
    leaderboard_sort_by: Optional[LeaderboardSortBy] = None

    @field_validator("max_active_referrers", mode="before")
    @classmethod
    def _max_active_referrers_as_int(cls, v: Any) -> Any:
        return _coerce_max_active_referrers(v)
    
    # Game Module Configuration
    is_runner_game_visible: Optional[bool] = None
    is_miner_game_visible: Optional[bool] = None
    is_tictactoe_game_visible: Optional[bool] = None
    is_sudoku_game_visible: Optional[bool] = None
    is_collage_game_visible: Optional[bool] = None
    is_arrow_game_visible: Optional[bool] = None
    is_twenty48_game_visible: Optional[bool] = None
    is_tile_swap_game_visible: Optional[bool] = None
    error_report_email: Optional[str] = None
    global_push_message: Optional[str] = None
    global_push_messages: Optional[Dict[str, str]] = None
    whats_new_json: Optional[List[Dict[str, Any]]] = None
    
    
    # Version Control
    # Version Control
    latest_version_android: Optional[str] = None
    min_version_android: Optional[str] = None
    update_url_android: Optional[str] = None
    
    latest_version_ios: Optional[str] = None
    min_version_ios: Optional[str] = None
    update_url_ios: Optional[str] = None
    
    latest_version_windows: Optional[str] = None
    min_version_windows: Optional[str] = None
    update_url_windows: Optional[str] = None

    @field_validator("global_push_messages", mode="before")
    @classmethod
    def _normalize_global_push_messages_update(cls, v: Any) -> Any:
        if v is None:
            return None
        if not isinstance(v, dict):
            raise ValueError("global_push_messages must be an object of {lang: text}")
        out: Dict[str, str] = {}
        for key, val in v.items():
            if key is None or val is None:
                continue
            k = str(key).strip().split("-")[0].split("_")[0].lower()
            if isinstance(val, str):
                out[k] = val
            else:
                out[k] = str(val)
        return out or None

    @field_validator(
        "update_url_android",
        "update_url_ios",
        "update_url_windows",
        mode="before",
    )
    @classmethod
    def _validate_update_url(cls, v: Any) -> Any:
        return _validate_http_url(v)

    @field_validator("whats_new_json", mode="before")
    @classmethod
    def _validate_whats_new_payload(cls, v: Any) -> Any:
        return _validate_whats_new_json(v)

    @field_validator("time_extension_slots", mode="before")
    @classmethod
    def _validate_time_extension_slots(cls, v: Any) -> Any:
        # minutes; cap at 7 days so a typo can't extend a session indefinitely
        return _validate_int_list_json(v, field="time_extension_slots", min_value=1, max_value=10_080, max_len=20)

    @field_validator("verification_backoff_delays", mode="before")
    @classmethod
    def _validate_verification_backoff_delays(cls, v: Any) -> Any:
        # seconds; cap at 24 hours
        return _validate_int_list_json(v, field="verification_backoff_delays", min_value=1, max_value=86_400, max_len=20)

    @field_validator("game_boost_config", mode="before")
    @classmethod
    def _validate_game_boost_config(cls, v: Any) -> Any:
        return _validate_object_json(v, field="game_boost_config")

    @field_validator("game_reward_config", mode="before")
    @classmethod
    def _validate_game_reward_config(cls, v: Any) -> Any:
        return _validate_object_json(v, field="game_reward_config")

    @field_validator("error_report_email", mode="before")
    @classmethod
    def _validate_error_report_email(cls, v: Any) -> Any:
        if v is None:
            return None
        if not isinstance(v, str):
            raise ValueError("error_report_email must be a string")
        s = v.strip()
        if s == "":
            return None
        # Lightweight format check (Pydantic's EmailStr round-trip would be
        # stricter but raises on instantiation; we treat empty + obviously
        # malformed addresses uniformly here). Backend SMTP failure on send
        # is still possible and is logged but never reaches the client.
        if "@" not in s or "." not in s.split("@", 1)[1] or len(s) > 320:
            raise ValueError("error_report_email must look like an email address")
        return s


class PayoutHistoryResponse(BaseModel):
    id: uuid.UUID
    catcoin_address: str
    amount_cat: float
    status: str
    txid: Optional[str] = None
    created_at: datetime
    sent_at: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)
    
    @field_serializer('id')
    def serialize_uuid(self, v):
        return str(v)

class UserDeleteRequest(BaseModel):
    email: str
    password: str

class XPostRequest(BaseModel):
    # X (Twitter) hard-caps tweet text at 280 chars; reject longer payloads
    # before we burn an API call. min_length=1 stops empty-tweet 422s.
    text: str = Field(..., min_length=1, max_length=280)
    reward_amount: float = Field(default=1.0, ge=0, le=1_000_000)
    expires_in_days: int = Field(default=10, ge=1, le=365)


class ClientErrorReport(BaseModel):
    """Payload for POST /v1/diagnostics/client-error.

    All strings are conservatively bounded so a misbehaving client can't
    exhaust the operator's inbox with megabyte error messages. ``user_id``
    is optional because reports may arrive before/while auth is broken.
    """

    # Short stable grouping key the client picks (e.g. "auth_resume_blocked",
    # "game_submit_failed"). Dedupes per (user_id, fingerprint) at the
    # endpoint so a single device flooding the same condition only emits
    # one email per hour.
    fingerprint: str = Field(..., min_length=1, max_length=128)
    user_id: Optional[uuid.UUID] = None
    app_version: str = Field(..., min_length=1, max_length=64)
    platform: str = Field(..., min_length=1, max_length=32)
    os_version: Optional[str] = Field(default=None, max_length=128)
    locale: Optional[str] = Field(default=None, max_length=32)
    screen: Optional[str] = Field(default=None, max_length=128)
    error_class: Optional[str] = Field(default=None, max_length=256)
    error_message: Optional[str] = Field(default=None, max_length=2048)
    http_status: Optional[int] = Field(default=None, ge=0, le=999)
    occurred_at: Optional[datetime] = None
    # Optional tail of recent client-side actions. Cap so a chatty client
    # can't blow past the 8 KB target total payload size.
    breadcrumbs: List[str] = Field(default_factory=list, max_length=20)

    @field_validator("breadcrumbs", mode="before")
    @classmethod
    def _validate_breadcrumbs(cls, v: Any) -> Any:
        if v is None:
            return []
        if not isinstance(v, list):
            raise ValueError("breadcrumbs must be a list of strings")
        out: list[str] = []
        for i, item in enumerate(v):
            if not isinstance(item, str):
                raise ValueError(f"breadcrumbs[{i}] must be a string")
            if len(item) > 256:
                raise ValueError(f"breadcrumbs[{i}] too long (max 256)")
            out.append(item)
        return out


class ClientErrorAck(BaseModel):
    """Response for POST /v1/diagnostics/client-error.

    Always 202-accepted on a valid payload, but we tell the client whether
    we deduped the report (so it can decide not to retry) and whether the
    mail step actually fired (operators care; clients should ignore it).
    """

    accepted: bool = True
    deduplicated: bool = False
    emailed: bool = False


# ==================== Game Schemas ====================

class GameSessionStartResponse(BaseModel):
    session_id: uuid.UUID
    session_token: str

    @field_serializer('session_id')
    def serialize_uuid(self, v):
        return str(v)

class GameSessionSubmit(BaseModel):
    session_token: str
    score: int
    coins_collected: int
    distance_meters: int
    game_type: Optional[str] = "RUNNER"

class GameSessionResponse(BaseModel):
    id: uuid.UUID
    score: int
    coins_collected: int
    distance_meters: int
    game_type: str = "RUNNER"
    reward_catoshi: int
    start_time: datetime
    end_time: Optional[datetime] = None
    validated: bool
    game_boost_awarded: bool = False
    game_boost_percentage: Optional[float] = None
    game_boost_duration_minutes: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)

    @field_serializer('id')
    def serialize_uuid(self, v):
        return str(v)

class GameHistoryResponse(BaseModel):
    sessions: List[GameSessionResponse]
    total_catoshi_earned: int

# ==================== Game Status & Leaderboard ====================

class GameStatusItem(BaseModel):
    game_type: str
    play_count: int
    max_games: Optional[int]
    cooldown_until: Optional[datetime] = None
    can_play: bool
    reward: Optional[int] = None

class GameStatusResponse(BaseModel):
    games: List[GameStatusItem]

class GameLeaderboardEntry(BaseModel):
    rank: int
    username: str
    display_name: Optional[str] = None
    country: Optional[str] = None
    score: int
    id: uuid.UUID

    @field_serializer('id')
    def serialize_uuid(self, v):
        return str(v)

class GameLeaderboardResponse(BaseModel):
    game_type: str
    leaders: List[GameLeaderboardEntry]

# ==================== Game Boost Schemas ====================

class UserGameBoostResponse(BaseModel):
    id: uuid.UUID
    percentage: float
    duration_minutes: int
    is_used: bool
    earned_at: datetime
    
    model_config = ConfigDict(from_attributes=True)
    
    @field_serializer('id')
    def serialize_uuid(self, v):
        return str(v)

class ActivateBoostRequest(BaseModel):
    boost_id: uuid.UUID

# ==================== Special Bonus Schemas ====================

class SpecialBonusResponse(BaseModel):
    code: str
    amount: float
    is_used: bool
    used_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class SpecialBonusRedeemRequest(BaseModel):
    code: str

class SpecialBonusGenerateRequest(BaseModel):
    # The handler does an N+1 uniqueness check per code; cap the batch so a
    # typo'd zero can't generate millions of rows in one call.
    amount: float = Field(..., gt=0, le=1_000_000)
    count: int = Field(default=1, ge=1, le=500)


# ==================== Referral milestone bonus ====================

class ReferralBonusMinedDaysCondition(BaseModel):
    current: int
    required: int
    met: bool


class ReferralBonusMiningRewardCondition(BaseModel):
    current_catoshi: int
    required_catoshi: int
    met: bool


class ReferralBonusGameRewardCondition(BaseModel):
    current_catoshi: int
    required_catoshi: int
    met: bool


class ReferralBonusConditionsResponse(BaseModel):
    mined_days: ReferralBonusMinedDaysCondition
    mining_reward: ReferralBonusMiningRewardCondition
    game_reward: ReferralBonusGameRewardCondition


class ReferralListItemResponse(BaseModel):
    referral_id: uuid.UUID
    referee_user_id: uuid.UUID
    referee_name: str
    referee_joined_at: datetime
    referred_at: datetime
    bonus_amount_catoshi: int
    bonus_status: str
    conditions_met_count: int

    @field_serializer("referral_id", "referee_user_id")
    def serialize_uuid(self, v):
        return str(v)


class ReferralDetailResponse(BaseModel):
    referral_id: uuid.UUID
    referrer_user_id: uuid.UUID
    referee_user_id: uuid.UUID
    referee_name: str
    referee_joined_at: datetime
    referred_at: datetime
    bonus_amount_catoshi: int
    bonus_status: str
    bonus_awarded_at: Optional[datetime] = None
    conditions: ReferralBonusConditionsResponse
    conditions_met_count: int
    status_ui_hint: str = ""

    @field_serializer("referral_id", "referrer_user_id", "referee_user_id")
    def serialize_uuid(self, v):
        return str(v)


class ReferralBonusListResponse(BaseModel):
    items: List[ReferralListItemResponse]


class AdminReferralBonusRowResponse(BaseModel):
    referral_id: uuid.UUID
    referrer_user_id: uuid.UUID
    referrer_username: str
    referee_user_id: uuid.UUID
    referee_username: str
    referred_at: datetime
    bonus_status: str
    mined_days_count: int
    mining_reward_catoshi: int
    game_reward_catoshi: int
    bonus_eligible_at: Optional[datetime] = None
    bonus_awarded_at: Optional[datetime] = None
    bonus_review_required: bool
    conditions_met_count: int

    @field_serializer(
        "referral_id",
        "referrer_user_id",
        "referee_user_id",
    )
    def serialize_uuid(self, v):
        return str(v)


class AdminReferralListResponse(BaseModel):
    items: List[AdminReferralBonusRowResponse]
    total: int
    skip: int
    limit: int


class ReferralBonusLedgerEntrySnippet(BaseModel):
    id: uuid.UUID
    amount: float
    reward_type: str
    created_at: datetime
    description: Optional[str] = None

    @field_serializer("id")
    def serialize_uuid(self, v):
        return str(v)


class AdminReferralDetailFullResponse(BaseModel):
    """Admin referral detail: user-facing fields + snapshots + ledger + review metadata."""

    referral_id: uuid.UUID
    referrer_user_id: uuid.UUID
    referrer_username: str
    referee_user_id: uuid.UUID
    referee_username: str
    referee_joined_at: datetime
    referred_at: datetime
    bonus_amount_catoshi: int
    bonus_status: str
    bonus_eligible_at: Optional[datetime] = None
    bonus_awarded_at: Optional[datetime] = None
    conditions: ReferralBonusConditionsResponse
    conditions_met_count: int
    status_ui_hint: str
    live_mined_days: int
    live_mining_reward_catoshi: int
    live_game_reward_catoshi: int
    last_evaluated_at: Optional[datetime] = None
    bonus_awarded_ledger: Optional[ReferralBonusLedgerEntrySnippet] = None
    bonus_review_required: bool = False
    bonus_review_note: Optional[str] = None
    bonus_reviewed_by: Optional[uuid.UUID] = None
    bonus_reviewed_at: Optional[datetime] = None

    @field_serializer(
        "referral_id",
        "referrer_user_id",
        "referee_user_id",
        "bonus_reviewed_by",
    )
    def serialize_uuid(self, v):
        return str(v) if v else None


class AdminReferralReviewRequest(BaseModel):
    action: str = Field(
        ...,
        description="under_review | approve | reject | force_credit",
    )
    note: Optional[str] = None

    @field_validator("action")
    @classmethod
    def normalize_action(cls, v: str) -> str:
        return (v or "").strip().lower()


class ReferralBonusNoteRequest(BaseModel):
    note: Optional[str] = None


class ReferralBonusRejectRequest(BaseModel):
    note: Optional[str] = None


class ReferralBonusForceAwardRequest(BaseModel):
    note: str = Field(..., min_length=1)
