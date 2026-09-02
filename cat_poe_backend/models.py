import uuid
import enum
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Enum, Integer, Float, Date, Index, UniqueConstraint, BigInteger, text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from database import Base

class MissionType(str, enum.Enum):
    AD = "AD"
    SOCIAL = "SOCIAL"
    OTHER = "OTHER"

class MiningStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    COMPLETED = "COMPLETED"

class SessionType(str, enum.Enum):
    BASE = "BASE"
    REFERRAL_BOOST = "REFERRAL_BOOST"
    GAME_BOOST = "GAME_BOOST"

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String, unique=True, index=True, nullable=False)  # 9-digit ID starting with 9
    email = Column(String, unique=True, index=True, nullable=False)
    display_name = Column(String, nullable=True)  # User-editable display name
    hashed_password = Column(String, nullable=False)
    referral_code = Column(String, unique=True, index=True, nullable=False)
    referred_by = Column(String, nullable=True)  # Referral code used during signup
    balance = Column(Float, default=0.0)
    total_earnings = Column(Float, default=0.0)  # Denormalized for performance
    last_active_at = Column(DateTime, default=datetime.utcnow)
    is_admin = Column(Boolean, default=False)
    email_verified = Column(Boolean, default=False)
    verification_code = Column(String(6), nullable=True)
    verification_code_expires = Column(DateTime, nullable=True)
    # Password reset OTP (separate from email verification to avoid shared state)
    password_reset_code = Column(String(6), nullable=True)
    password_reset_expires = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_deleted = Column(Boolean, default=False)
    deleted_at = Column(DateTime, nullable=True)

    # Social IDs
    discord_id = Column(String, nullable=True)
    discord_id_verified = Column(Boolean, default=False)
    discord_id_locked = Column(Boolean, default=False)
    discord_id_old = Column(String, nullable=True)
    
    telegram_id = Column(String, nullable=True)
    telegram_id_verified = Column(Boolean, default=False)
    telegram_id_locked = Column(Boolean, default=False)
    telegram_id_old = Column(String, nullable=True)
    
    x_id = Column(String, nullable=True)
    x_id_verified = Column(Boolean, default=False)
    x_id_locked = Column(Boolean, default=False)
    x_id_old = Column(String, nullable=True)
    
    facebook_id = Column(String, nullable=True)
    facebook_id_verified = Column(Boolean, default=False)
    facebook_id_locked = Column(Boolean, default=False)
    facebook_id_old = Column(String, nullable=True)
    
    whatsapp_id = Column(String, nullable=True)
    whatsapp_id_verified = Column(Boolean, default=False)
    whatsapp_id_locked = Column(Boolean, default=False)
    whatsapp_id_old = Column(String, nullable=True)

    # Location
    country = Column(String(2), default="US") # ISO Alpha-2 country code
    country_source = Column(String(10), nullable=True) # IP, LOCALE

    # Anti-Cheat Tracking
    ip_address = Column(String, nullable=True)
    device_id = Column(String, nullable=True, index=True) # Installation UUID
    is_suspicious = Column(Boolean, default=False)

    # Google Play Age Signals (Texas SB 2420, rolling out via Play Age Signals API v0.0.3).
    # Stored verbatim from the platform; allowed values mirror the API enum:
    # null / "not_checked" / "not_required" / "verified" / "not_verified" / "pending".
    # Admin override is allowed via PUT /admin/users/{id}. See
    # docs/play_age_signals_integration.md for the wiring plan.
    age_signal_status = Column(String, nullable=True)
    age_signal_checked_at = Column(DateTime, nullable=True)

    # Withdrawal Permissions (Individual Controls) - Default to OFF
    can_withdraw_mining = Column(Boolean, default=False)
    can_withdraw_referrals = Column(Boolean, default=False)
    can_withdraw_missions = Column(Boolean, default=False)
    can_withdraw_games = Column(Boolean, default=False)
    can_withdraw_game_boosts = Column(Boolean, default=False)

    # Up to 6 earned badge UUIDs (strings) to highlight on profile, in display order
    showcase_badge_ids = Column("profile_showcase_badge_ids", JSONB, nullable=True, server_default=text("'[]'::jsonb"))

    wallets = relationship("Wallet", back_populates="user")
    mining_sessions = relationship("MiningSession", back_populates="user", foreign_keys="MiningSession.user_id")
    refresh_tokens = relationship("RefreshToken", back_populates="user")
    suspicious_activities = relationship("SuspiciousActivity", back_populates="user", foreign_keys="SuspiciousActivity.user_id")
    ad_views = relationship("AdView", back_populates="user")
    badges = relationship("UserBadge", back_populates="user")

    __table_args__ = (Index("ix_users_last_active_at_engagement", "last_active_at"),)


class UserBadge(Base):
    """Permanent awards/badges given to users"""
    __tablename__ = "user_badges"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    badge_type = Column(String, nullable=False) # 'weekly_top', 'monthly_top', 'monthly_global_podium', 'all_time_top'
    description = Column(String, nullable=True)
    awarded_at = Column(DateTime, default=datetime.utcnow)
    # Monthly podium awards (global top 3): calendar month + rank + scope
    period_year = Column(Integer, nullable=True)
    period_month = Column(Integer, nullable=True)  # 1–12
    podium_rank = Column(Integer, nullable=True)  # 1–3
    award_scope = Column(String, nullable=True)  # GLOBAL, REGIONAL, GAME
    region_code = Column(String(2), nullable=True)  # ISO country for regional podium
    game_type = Column(String, nullable=True)  # RUNNER, TICTACTOE, … for game podium

    user = relationship("User", back_populates="badges")
    
    __table_args__ = (
        Index('idx_user_badges', 'user_id'),
    )


class SocialVerificationAudit(Base):
    """Audit trail for social verification rewards, revocations, and ID changes."""
    __tablename__ = "social_verification_audit"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    action = Column(String(64), nullable=False)
    platform = Column(String(32), nullable=True)
    detail = Column(String(1000), nullable=True)
    amount = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (Index("idx_social_verification_audit_user", "user_id"),)


class RefreshToken(Base):
    """Refresh tokens for persistent authentication"""
    __tablename__ = "refresh_tokens"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token = Column(String, unique=True, nullable=False, index=True)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    revoked = Column(Boolean, default=False)
    device_info = Column(String(500), nullable=True)
    # Rotation lineage: reuse of an old token revokes all tokens in the same family
    family_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    
    user = relationship("User", back_populates="refresh_tokens")
    
    __table_args__ = (
        Index('idx_token', 'token'),
        Index('idx_user_tokens', 'user_id', 'revoked'),
    )

class SuspiciousActivity(Base):
    """Logs of suspicious events for fraud detection"""
    __tablename__ = "suspicious_activities"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    activity_type = Column(String, nullable=False) # MULTIPLE_DEVICE, DUPLICATE_WALLET
    evidence = Column(String, nullable=False)      # Conflicting ID/Address
    related_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True) # The other user involved
    is_resolved = Column(Boolean, default=False)
    detected_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="suspicious_activities", foreign_keys=[user_id])
    related_user = relationship("User", foreign_keys=[related_user_id])


class UserPingNotification(Base):
    """Lightweight in-app ping / nudge (referral reminders, admin inactive outreach)."""

    __tablename__ = "user_ping_notifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    recipient_user_id = Column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    sender_user_id = Column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    kind = Column(String(64), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        Index("idx_user_ping_recipient_created", "recipient_user_id", "created_at"),
        Index("idx_user_ping_kind", "kind"),
        Index(
            "idx_user_ping_dedupe_lookup",
            "recipient_user_id",
            "kind",
            "sender_user_id",
            "created_at",
        ),
    )


class WalletSource(str, enum.Enum):
    GENERATED = "GENERATED"
    IMPORTED = "IMPORTED"
    MANUAL = "MANUAL"

class Wallet(Base):
    __tablename__ = "wallets"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    catcoin_address = Column(String, nullable=False)
    is_primary = Column(Boolean, default=False)
    source = Column(Enum(WalletSource), default=WalletSource.MANUAL)

    user = relationship("User", back_populates="wallets")

class Mission(Base):
    __tablename__ = "missions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code = Column(String, unique=True, index=True, nullable=False)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    link = Column(String, nullable=True)
    icon = Column(String, nullable=True) # e.g., "discord", "twitter"
    type = Column(Enum(MissionType), nullable=False)
    reward_amount = Column(Float, nullable=False, default=100000.0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)
    prerequisite_id = Column(UUID(as_uuid=True), ForeignKey("missions.id"), nullable=True)
    
    prerequisite = relationship("Mission", remote_side=[id])

class UserMission(Base):
    __tablename__ = "user_missions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    mission_id = Column(UUID(as_uuid=True), ForeignKey("missions.id"), nullable=False)
    completed_at = Column(DateTime, default=datetime.utcnow)
    status = Column(String, default="COMPLETED") # PENDING, COMPLETED, REJECTED
    verification_proof = Column(String, nullable=True) # User submitted ID/Handle
    
    __table_args__ = (
        UniqueConstraint('user_id', 'mission_id', name='_user_mission_uc'),
    )

class MiningSession(Base):
    __tablename__ = "mining_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    session_type = Column(Enum(SessionType), default=SessionType.BASE)
    mining_for = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)  # For REFERRAL_BOOST type
    start_time = Column(DateTime, default=datetime.utcnow)
    end_time = Column(DateTime, nullable=False)
    status = Column(Enum(MiningStatus), default=MiningStatus.ACTIVE)
    total_earned = Column(Float, default=0.0)
    
    # NEW: Dynamic Catoshi Display
    reward_y = Column(Integer, default=0)
    reward_t = Column(Integer, default=1)
    
    # NEW: Completion tracking
    completed_at = Column(DateTime, nullable=True)
    ledger_entry_id = Column(UUID(as_uuid=True), ForeignKey("earnings_ledger.id"), nullable=True)

    # JSON: {"slots":[5,6],"cooldowns":{"5":"..."},"inactive_hours":[6]}
    time_boost_slots_data = Column(String, nullable=True)

    user = relationship("User", back_populates="mining_sessions", foreign_keys=[user_id])
    mining_for_user = relationship("User", foreign_keys=[mining_for])

class RewardType(str, enum.Enum):
    MINING_BASE = "MINING_BASE"
    MINING_REFERRAL_BOOST = "MINING_REFERRAL_BOOST"
    SOCIAL_FACEBOOK = "SOCIAL_FACEBOOK"
    SOCIAL_X = "SOCIAL_X"
    SOCIAL_DISCORD = "SOCIAL_DISCORD"
    SOCIAL_TELEGRAM = "SOCIAL_TELEGRAM"
    MISSION_COMPLETION = "MISSION_COMPLETION"
    REFERRAL_SIGNUP_BONUS = "REFERRAL_SIGNUP_BONUS"
    AIRDROP = "AIRDROP"
    WITHDRAWAL = "WITHDRAWAL"  # NEW: For withdrawal transactions
    GAME_REWARD = "GAME_REWARD"  # Game runner rewards
    GAME_BOOST = "GAME_BOOST"
    SPECIAL_BONUS = "SPECIAL_BONUS"
    REFERRAL_BONUS = "REFERRAL_BONUS"  # One-time bonus to referrer when referee meets milestones


class Referral(Base):
    """Referrer ↔ referee link and referral milestone bonus state."""

    __tablename__ = "referrals"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    referrer_user_id = Column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    referee_user_id = Column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    referred_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    bonus_amount_catoshi = Column(BigInteger, nullable=False, server_default="10000000")
    bonus_status = Column(String(32), nullable=False, server_default="pending")
    bonus_eligible_at = Column(DateTime, nullable=True)
    bonus_awarded_at = Column(DateTime, nullable=True)
    # Ledger row id for audit; FK added in DB migration (avoid circular create with earnings_ledger.referral_id).
    bonus_awarded_txn_id = Column(UUID(as_uuid=True), nullable=True)
    bonus_review_required = Column(Boolean, nullable=False, server_default="false")
    bonus_review_note = Column(String(2000), nullable=True)
    bonus_reviewed_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    bonus_reviewed_at = Column(DateTime, nullable=True)

    mined_days_count = Column(Integer, nullable=False, server_default="0")
    mining_reward_catoshi = Column(BigInteger, nullable=False, server_default="0")
    game_reward_catoshi = Column(BigInteger, nullable=False, server_default="0")
    conditions_met_count = Column(Integer, nullable=False, server_default="0")
    last_evaluated_at = Column(DateTime, nullable=True)

    __table_args__ = (
        UniqueConstraint("referrer_user_id", "referee_user_id", name="uq_referrals_referrer_referee"),
        Index("ix_referrals_referrer", "referrer_user_id"),
        Index("ix_referrals_referee", "referee_user_id"),
    )


class EarningsLedger(Base):
    __tablename__ = "earnings_ledger"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    amount = Column(Float, nullable=False)
    reward_type = Column(Enum(RewardType), nullable=False)
    referral_id = Column(UUID(as_uuid=True), ForeignKey("referrals.id"), nullable=True)
    
    # NEW: For mining aggregation (NULL for non-mining transactions)
    aggregation_date = Column(Date, nullable=True)
    
    # NEW: Description for non-mining transactions
    description = Column(String(500), nullable=True)
    
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    payout_id = Column(UUID(as_uuid=True), ForeignKey("payouts.id"), nullable=True)
    
    __table_args__ = (
        Index('idx_user_date_type', 'user_id', 'aggregation_date', 'reward_type'),
    )

class LedgerSessionMapping(Base):
    """Junction table linking ledger entries to mining sessions"""
    __tablename__ = "ledger_session_mappings"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ledger_entry_id = Column(UUID(as_uuid=True), ForeignKey("earnings_ledger.id"), nullable=False)
    session_id = Column(UUID(as_uuid=True), ForeignKey("mining_sessions.id"), nullable=False)
    session_contribution = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        UniqueConstraint('session_id', name='_unique_session_uc'),
    )

class AdminConfig(Base):
    __tablename__ = "admin_config"

    id = Column(Integer, primary_key=True)  # Singleton row
    global_withdrawal_enabled = Column(Boolean, default=True)
    ad_required_for_mining_start = Column(Boolean, default=False)
    ad_required_for_speed_boost = Column(Boolean, default=False)
    ad_required_for_time_boost = Column(Boolean, default=False)
    time_boost_duration_seconds = Column(Integer, default=14400)  # 4 hours
    speed_boost_per_referral = Column(Float, default=10.0)
    base_hashrate = Column(Float, default=100.0)
    android_ad_unit_id = Column(String, nullable=True)
    ios_ad_unit_id = Column(String, nullable=True)
    app_ads_content = Column(String, nullable=True)
    game_ads_enabled = Column(Boolean, default=False)
    
    # NEW: Mining configuration
    base_mining_duration_minutes = Column(Integer, default=480)  # 8 hours
    max_mining_duration_minutes = Column(Integer, default=1440)  # 24 hours
    time_extension_slots = Column(String, default="[120, 180, 240, 300, 360]")  # 2h, 3h, 4h, 5h, 6h
    max_referral_boost_hashrate = Column(Float, default=100.0)  # Max 100 MH/s boost
    leaderboard_sort_by = Column(String, default="BALANCE")  # BALANCE or TOTAL_EARNINGS
    # JSON blobs: source of truth is DB; defaults live in admin_config_defaults.py + seed_admin_game_config.py
    game_boost_config = Column(String, nullable=True)
    game_reward_config = Column(String, nullable=True)

    # Bot Configuration
    discord_bot_token = Column(String, nullable=True)
    discord_guild_id = Column(String, nullable=True)
    telegram_bot_token = Column(String, nullable=True)
    telegram_chat_id = Column(String, nullable=True)
    
    # X (Twitter) Configuration
    x_bearer_token = Column(String, nullable=True)
    x_community_username = Column(String, nullable=True)
    x_consumer_key = Column(String, nullable=True)
    x_consumer_secret = Column(String, nullable=True)
    x_access_token = Column(String, nullable=True)
    x_access_token_secret = Column(String, nullable=True)
    x_client_id = Column(String, nullable=True)
    x_client_secret = Column(String, nullable=True)
    enable_verification_release = Column(Boolean, default=True)
    enable_verification_debug = Column(Boolean, default=True)
    # Default: 2m, 3m, 5m, 7m, 10m (in seconds)
    verification_backoff_delays = Column(String, default="[120, 180, 300, 420, 600]")

    # Wallet & Blockchain Configuration
    coin_explorer_api_key = Column(String, nullable=True)
    enable_wallet_holding_days = Column(Boolean, default=True)
    enable_profile_picture = Column(Boolean, default=False)
    
    # Dynamic catoshi Reward configuration
    use_manual_cat_price = Column(Boolean, default=False)
    manual_cat_price_usdt = Column(Integer, default=50000)  # default $0.05 equivalent
    coingecko_coin_id = Column(String, default="catcoins")
    catoshi_yield_percentage = Column(Float, default=100.0)
    referral_boost_percentage = Column(Float, default=10.0)
    max_active_referrers = Column(Integer, default=10)
    # Catoshi credited once when a referred user verifies email (or links referrer); 0 disables.
    referral_signup_bonus_referee_amount = Column(Float, default=100.0)
    referral_signup_bonus_referrer_amount = Column(Float, default=50.0)
    # One-time referrer milestone bonus per invite (catoshi); used when creating referral rows.
    referral_milestone_bonus_catoshi = Column(
        BigInteger, nullable=False, server_default="10000000"
    )

    # Game Module Configuration
    is_runner_game_visible = Column(Boolean, default=True)
    is_miner_game_visible = Column(Boolean, default=True)
    is_tictactoe_game_visible = Column(Boolean, default=True)
    is_sudoku_game_visible = Column(Boolean, default=True)
    is_collage_game_visible = Column(Boolean, default=True)
    is_arrow_game_visible = Column(Boolean, default=True)
    is_twenty48_game_visible = Column(Boolean, default=True)
    is_tile_swap_game_visible = Column(Boolean, default=True)

    # Where client crash / unrecoverable-error reports are mailed when the
    # ERROR_REPORT_EMAIL env var is unset. Plaintext (not a secret). Leave
    # null to accept reports but skip the email step.
    error_report_email = Column(String, nullable=True)

    # Global Announcement Message (localized). Legacy VARCHAR kept for migrations / old tooling.
    global_push_message = Column(String, nullable=True)
    global_push_messages = Column(JSONB, nullable=True)

    # In-app What's New releases (newest first; see services/config_i18n.py shapes)
    whats_new_json = Column(JSONB, nullable=True, server_default=text("'[]'::jsonb"))

    # Version Control. Defaults match the currently shipping client so a fresh
    # DB doesn't make the force-update gate a no-op. Bump these (or set via
    # PUT /admin/config) on every release so older clients are blocked.
    # Android
    latest_version_android = Column(String, default="1.10.7")
    min_version_android = Column(String, default="1.10.0")
    update_url_android = Column(String, default="https://play.google.com/store/apps/details?id=org.catcoin.cat")

    # iOS
    latest_version_ios = Column(String, default="1.10.7")
    min_version_ios = Column(String, default="1.10.0")
    update_url_ios = Column(String, default="https://apps.apple.com/app/id123456789")

    # Windows
    latest_version_windows = Column(String, default="1.10.7")
    min_version_windows = Column(String, default="1.10.0")
    update_url_windows = Column(String, default="https://catcoin.in/download")

class Payout(Base):
    __tablename__ = "payouts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    catcoin_address = Column(String, nullable=False)
    amount_cat = Column(Float, nullable=False)
    txid = Column(String, nullable=True)  # Blockchain transaction ID
    status = Column(String, default="pending")  # pending, sent, failed
    created_at = Column(DateTime, default=datetime.utcnow)
    sent_at = Column(DateTime, nullable=True)

class DeletedIdentity(Base):
    """Stores hashed identities of deleted users to prevent reward farming/re-registration abuse"""
    __tablename__ = "deleted_identities"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    identity_hash = Column(String, unique=True, index=True, nullable=False)  # SHA256 of email or other unique identifier
    total_rewards = Column(Float, default=0.0)
    deleted_at = Column(DateTime, default=datetime.utcnow)

class AdView(Base):
    """Tracks verified AdMob rewarded ad views"""
    __tablename__ = "ad_views"

    transaction_id = Column(String, primary_key=True)  # From AdMob
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    timestamp = Column(DateTime, nullable=False)  # When ad was watched (from AdMob callback)
    verified = Column(Boolean, default=False)
    used_at = Column(DateTime, nullable=True)     # When reward was claimed (mining started/extended)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="ad_views")

class GameSession(Base):
    __tablename__ = "game_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    session_token = Column(String, unique=True, nullable=False, index=True)
    start_time = Column(DateTime, default=datetime.utcnow)
    end_time = Column(DateTime, nullable=True)
    score = Column(Integer, default=0)
    coins_collected = Column(Integer, default=0)
    distance_meters = Column(Integer, default=0)
    game_type = Column(String, default="RUNNER") # RUNNER, TICTACTOE, SUDOKU, COLLAGE
    validated = Column(Boolean, default=False)

    user = relationship("User")

    __table_args__ = (
        Index('idx_game_sessions_user', 'user_id'),
    )

class GameReward(Base):
    __tablename__ = "game_rewards"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    session_id = Column(UUID(as_uuid=True), ForeignKey("game_sessions.id"), nullable=False)
    reward_catoshi = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")
    session = relationship("GameSession")

    __table_args__ = (
        Index('idx_game_rewards_user', 'user_id'),
    )

class UserGameBoost(Base):
    """Inventory of boosts earned from games but not yet activated"""
    __tablename__ = "user_game_boosts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    percentage = Column(Float, nullable=False) # e.g. 10.0 for 10%
    duration_minutes = Column(Integer, nullable=False) # e.g. 60 for 1 hour
    is_used = Column(Boolean, default=False)
    session_id = Column(UUID(as_uuid=True), ForeignKey("mining_sessions.id"), nullable=True) # Linked once activated
    earned_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User")

class GameCooldown(Base):
    """Tracks play counts and active lockout periods for games"""
    __tablename__ = "game_cooldowns"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    game_type = Column(String, nullable=False) # TICTACTOE, SUDOKU, COLLAGE
    play_count = Column(Integer, default=0)
    cooldown_until = Column(DateTime, nullable=True) # If set and in future, user is blocked
    last_updated_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")

    __table_args__ = (
        UniqueConstraint('user_id', 'game_type', name='_user_game_cooldown_uc'),
    )

class SpecialBonusCode(Base):
    """Unique 24-character alpha-numeric codes for one-time rewards"""
    __tablename__ = "special_bonus_codes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code = Column(String(24), unique=True, index=True, nullable=False)
    amount = Column(Float, nullable=False) # Reward amount (Catoshi)
    is_used = Column(Boolean, default=False)
    used_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    used_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")
