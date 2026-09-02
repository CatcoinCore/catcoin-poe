"""Initial schema creation

Revision ID: initial_schema
Revises: 
Create Date: 2026-02-03 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect, text
from sqlalchemy.dialects import postgresql
from sqlalchemy.exc import IntegrityError, ProgrammingError

# revision identifiers, used by Alembic.
revision = 'initial_schema'
down_revision = None
branch_labels = None
depends_on = None


def _pg_table_exists(bind, schema: str, table: str) -> bool:
    """True if a base table (or partition) exists; more reliable than to_regclass alone for some PG/driver combos."""
    if bind.execute(
        sa.text(
            "SELECT EXISTS (SELECT 1 FROM information_schema.tables "
            "WHERE table_schema = :schema AND table_name = :tname)"
        ),
        {"schema": schema, "tname": table},
    ).scalar():
        return True
    return bool(
        bind.execute(
            sa.text(
                "SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_class c "
                "JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace "
                "WHERE n.nspname = :schema AND c.relname = :tname "
                "AND c.relkind IN ('r', 'p', 'v', 'm', 'f'))"
            ),
            {"schema": schema, "tname": table},
        ).scalar()
    )


def _clear_admin_config_name_conflicts(bind) -> None:
    """Remove orphan domain/type named admin_config so CREATE TABLE can register its row type.

    Duplicate pg_type_typname_nsp_index on CREATE TABLE usually means a leftover composite
    type, domain, or failed partial DDL — not only typtype='c' composites.
    """
    bind.execute(
        text(
            """
DO $d$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'admin_config'
      AND c.relkind IN ('r', 'p')
  ) THEN
    RETURN;
  END IF;
  EXECUTE 'DROP DOMAIN IF EXISTS public.admin_config CASCADE';
  EXECUTE 'DROP TYPE IF EXISTS public.admin_config CASCADE';
END
$d$;
"""
        )
    )


def _create_admin_config_table() -> None:
    op.create_table(
        "admin_config",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column(
            "ad_required_for_mining_start",
            sa.Boolean(),
            server_default="false",
            nullable=True,
        ),
        sa.Column(
            "ad_required_for_speed_boost",
            sa.Boolean(),
            server_default="false",
            nullable=True,
        ),
        sa.Column(
            "ad_required_for_time_boost",
            sa.Boolean(),
            server_default="false",
            nullable=True,
        ),
        sa.Column(
            "time_boost_duration_seconds",
            sa.Integer(),
            server_default="14400",
            nullable=True,
        ),
        sa.Column(
            "speed_boost_per_referral",
            sa.Float(),
            server_default="10.0",
            nullable=True,
        ),
        sa.Column("base_hashrate", sa.Float(), server_default="100.0", nullable=True),
        sa.Column("android_ad_unit_id", sa.String(), nullable=True),
        sa.Column("ios_ad_unit_id", sa.String(), nullable=True),
        sa.Column(
            "base_mining_duration_minutes",
            sa.Integer(),
            server_default="480",
            nullable=True,
        ),
        sa.Column(
            "max_mining_duration_minutes",
            sa.Integer(),
            server_default="1440",
            nullable=True,
        ),
        sa.Column(
            "time_extension_slots",
            sa.String(),
            server_default="[120, 180, 240, 300, 360]",
            nullable=True,
        ),
        sa.Column(
            "max_referral_boost_hashrate",
            sa.Float(),
            server_default="100.0",
            nullable=True,
        ),
        sa.Column("discord_bot_token", sa.String(), nullable=True),
        sa.Column("discord_guild_id", sa.String(), nullable=True),
        sa.Column("telegram_bot_token", sa.String(), nullable=True),
        sa.Column("telegram_chat_id", sa.String(), nullable=True),
        sa.Column("x_bearer_token", sa.String(), nullable=True),
        sa.Column("x_community_username", sa.String(), nullable=True),
        sa.Column(
            "enable_verification_release",
            sa.Boolean(),
            server_default="true",
            nullable=True,
        ),
        sa.Column(
            "enable_verification_debug",
            sa.Boolean(),
            server_default="true",
            nullable=True,
        ),
        sa.Column("coin_explorer_api_key", sa.String(), nullable=True),
        sa.Column(
            "enable_wallet_holding_days",
            sa.Boolean(),
            server_default="true",
            nullable=True,
        ),
        sa.PrimaryKeyConstraint("id"),
    )


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names(schema="public"))

    # 1. Admin Config — cross-check PG catalogs; skip create if table already there (avoids DuplicateTable).
    admin_exists = "admin_config" in tables or _pg_table_exists(bind, "public", "admin_config")
    if not admin_exists:
        _clear_admin_config_name_conflicts(bind)
        for attempt in range(2):
            try:
                _create_admin_config_table()
                break
            except (ProgrammingError, IntegrityError) as e:
                orig = str(getattr(e, "orig", e)).lower()
                if "already exists" not in orig and "duplicate" not in orig:
                    raise
                _clear_admin_config_name_conflicts(bind)
                if attempt == 1:
                    raise
    tables.add("admin_config")

    # 2. Users (Without is_deleted, deleted_at)
    if "users" not in tables:
        op.create_table('users',
            sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('username', sa.String(), nullable=False),
            sa.Column('email', sa.String(), nullable=False),
            sa.Column('display_name', sa.String(), nullable=True),
            sa.Column('hashed_password', sa.String(), nullable=False),
            sa.Column('referral_code', sa.String(), nullable=False),
            sa.Column('referred_by', sa.String(), nullable=True),
            sa.Column('balance', sa.Float(), server_default='0.0', nullable=True),
            sa.Column('last_active_at', sa.DateTime(), nullable=True),
            sa.Column('is_admin', sa.Boolean(), server_default='false', nullable=True),
            sa.Column('email_verified', sa.Boolean(), server_default='false', nullable=True),
            sa.Column('verification_code', sa.String(length=6), nullable=True),
            sa.Column('verification_code_expires', sa.DateTime(), nullable=True),
            sa.Column('created_at', sa.DateTime(), nullable=True),
            # Social IDs
            sa.Column('discord_id', sa.String(), nullable=True),
            sa.Column('telegram_id', sa.String(), nullable=True),
            sa.Column('x_id', sa.String(), nullable=True),
            sa.Column('facebook_id', sa.String(), nullable=True),
            sa.Column('whatsapp_id', sa.String(), nullable=True),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)
        op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
        op.create_index(op.f('ix_users_referral_code'), 'users', ['referral_code'], unique=True)
        tables.add("users")

    # 3. Refresh Tokens
    if "refresh_tokens" not in tables:
        op.create_table('refresh_tokens',
            sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('token', sa.String(), nullable=False),
            sa.Column('expires_at', sa.DateTime(), nullable=False),
            sa.Column('created_at', sa.DateTime(), nullable=True),
            sa.Column('revoked', sa.Boolean(), server_default='false', nullable=True),
            sa.Column('device_info', sa.String(length=500), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_refresh_tokens_token'), 'refresh_tokens', ['token'], unique=True)
        op.create_index('idx_user_tokens', 'refresh_tokens', ['user_id', 'revoked'], unique=False)
        tables.add("refresh_tokens")

    # 4. Wallets (Without source)
    if "wallets" not in tables:
        op.create_table('wallets',
            sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('catcoin_address', sa.String(), nullable=False),
            sa.Column('is_primary', sa.Boolean(), server_default='false', nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('id')
        )
        tables.add("wallets")

    # 5. Missions
    if "missions" not in tables:
        op.create_table('missions',
            sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('code', sa.String(), nullable=False),
            sa.Column('title', sa.String(), nullable=False),
            sa.Column('description', sa.String(), nullable=True),
            sa.Column('link', sa.String(), nullable=True),
            sa.Column('icon', sa.String(), nullable=True),
            sa.Column('type', sa.Enum('AD', 'SOCIAL', 'OTHER', name='missiontype'), nullable=False),
            sa.Column('reward_amount', sa.Float(), nullable=False),
            sa.Column('is_active', sa.Boolean(), server_default='true', nullable=True),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_missions_code'), 'missions', ['code'], unique=True)
        tables.add("missions")

    # 6. User Missions
    if "user_missions" not in tables:
        op.create_table('user_missions',
            sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('mission_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('completed_at', sa.DateTime(), nullable=True),
            sa.Column('status', sa.String(), server_default='COMPLETED', nullable=True),
            sa.Column('verification_proof', sa.String(), nullable=True),
            sa.ForeignKeyConstraint(['mission_id'], ['missions.id'], ),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('id'),
            sa.UniqueConstraint('user_id', 'mission_id', name='_user_mission_uc')
        )
        tables.add("user_missions")

    # 7. Mining Sessions
    if "mining_sessions" not in tables:
        op.create_table('mining_sessions',
            sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('session_type', sa.Enum('BASE', 'REFERRAL_BOOST', name='sessiontype'), server_default='BASE', nullable=True),
            sa.Column('mining_for', postgresql.UUID(as_uuid=True), nullable=True),
            sa.Column('start_time', sa.DateTime(), nullable=True),
            sa.Column('end_time', sa.DateTime(), nullable=False),
            sa.Column('status', sa.Enum('ACTIVE', 'COMPLETED', name='miningstatus'), server_default='ACTIVE', nullable=True),
            sa.Column('total_earned', sa.Float(), server_default='0.0', nullable=True),
            sa.Column('completed_at', sa.DateTime(), nullable=True),
            sa.PrimaryKeyConstraint('id'),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.ForeignKeyConstraint(['mining_for'], ['users.id'], )
        )
        tables.add("mining_sessions")

    # 8. Payouts
    if "payouts" not in tables:
        op.create_table('payouts',
            sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('catcoin_address', sa.String(), nullable=False),
            sa.Column('amount_cat', sa.Float(), nullable=False),
            sa.Column('txid', sa.String(), nullable=True),
            sa.Column('status', sa.String(), server_default='pending', nullable=True),
            sa.Column('created_at', sa.DateTime(), nullable=True),
            sa.Column('sent_at', sa.DateTime(), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('id')
        )
        tables.add("payouts")

    # 9. Earnings Ledger
    if "earnings_ledger" not in tables:
        op.create_table('earnings_ledger',
            sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('amount', sa.Float(), nullable=False),
            sa.Column('reward_type', sa.Enum('MINING_BASE', 'MINING_REFERRAL_BOOST', 'SOCIAL_FACEBOOK', 'SOCIAL_X', 'SOCIAL_DISCORD', 'SOCIAL_TELEGRAM', 'MISSION_COMPLETION', 'REFERRAL_SIGNUP_BONUS', 'AIRDROP', 'WITHDRAWAL', name='rewardtype'), nullable=False),
            sa.Column('aggregation_date', sa.Date(), nullable=True),
            sa.Column('description', sa.String(length=500), nullable=True),
            sa.Column('is_verified', sa.Boolean(), server_default='false', nullable=True),
            sa.Column('created_at', sa.DateTime(), nullable=True),
            sa.Column('payout_id', postgresql.UUID(as_uuid=True), nullable=True),
            sa.ForeignKeyConstraint(['payout_id'], ['payouts.id'], ),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index('idx_user_date_type', 'earnings_ledger', ['user_id', 'aggregation_date', 'reward_type'], unique=False)
        tables.add("earnings_ledger")

    # Now add FK to mining_sessions only if it doesn't exist
    if "mining_sessions" in tables:
        columns = [c["name"] for c in inspector.get_columns("mining_sessions", schema="public")]
        if 'ledger_entry_id' not in columns:
            op.add_column('mining_sessions', sa.Column('ledger_entry_id', postgresql.UUID(as_uuid=True), nullable=True))
            op.create_foreign_key('fk_mining_sessions_ledger', 'mining_sessions', 'earnings_ledger', ['ledger_entry_id'], ['id'])

    # 10. Ledger Session Mappings
    if "ledger_session_mappings" not in tables:
        op.create_table('ledger_session_mappings',
            sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('ledger_entry_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('session_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('session_contribution', sa.Float(), nullable=False),
            sa.Column('created_at', sa.DateTime(), nullable=True),
            sa.ForeignKeyConstraint(['ledger_entry_id'], ['earnings_ledger.id'], ),
            sa.ForeignKeyConstraint(['session_id'], ['mining_sessions.id'], ),
            sa.PrimaryKeyConstraint('id'),
            sa.UniqueConstraint('session_id', name='_unique_session_uc')
        )
        tables.add("ledger_session_mappings")


def downgrade() -> None:
    # Drop in reverse order
    op.drop_table('ledger_session_mappings')
    op.drop_constraint('fk_mining_sessions_ledger', 'mining_sessions', type_='foreignkey')
    op.drop_column('mining_sessions', 'ledger_entry_id')
    op.drop_table('earnings_ledger')
    op.drop_table('payouts')
    op.drop_table('mining_sessions')
    op.drop_table('user_missions')
    op.drop_table('missions')
    op.drop_table('wallets')
    op.drop_table('refresh_tokens')
    op.drop_table('users')
    op.drop_table('admin_config')
    
    # Drop Enums
    sa.Enum(name='missiontype').drop(op.get_bind(), checkfirst=True)
    sa.Enum(name='sessiontype').drop(op.get_bind(), checkfirst=True)
    sa.Enum(name='miningstatus').drop(op.get_bind(), checkfirst=True)
    sa.Enum(name='rewardtype').drop(op.get_bind(), checkfirst=True)
