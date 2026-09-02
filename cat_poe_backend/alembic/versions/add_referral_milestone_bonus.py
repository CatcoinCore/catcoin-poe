"""Referral milestone bonus table, ledger link, rewardtype enum value.

Revision ID: add_referral_milestone_bonus
Revises: polish_engagement_ping_indexes
Create Date: 2026-04-16

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "add_referral_milestone_bonus"
down_revision = "polish_engagement_ping_indexes"
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    # rewardtype: add REFERRAL_BONUS via app startup (main.py) if not present; avoids PG txn limits on ALTER TYPE.

    op.create_table(
        "referrals",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("referrer_user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("referee_user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("referred_at", sa.DateTime(), nullable=False),
        sa.Column(
            "bonus_amount_catoshi",
            sa.BigInteger(),
            server_default="10000000",
            nullable=False,
        ),
        sa.Column(
            "bonus_status",
            sa.String(length=32),
            server_default="pending",
            nullable=False,
        ),
        sa.Column("bonus_eligible_at", sa.DateTime(), nullable=True),
        sa.Column("bonus_awarded_at", sa.DateTime(), nullable=True),
        sa.Column("bonus_awarded_txn_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column(
            "bonus_review_required",
            sa.Boolean(),
            server_default="false",
            nullable=False,
        ),
        sa.Column("bonus_review_note", sa.String(length=2000), nullable=True),
        sa.Column("bonus_reviewed_by", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("bonus_reviewed_at", sa.DateTime(), nullable=True),
        sa.Column("mined_days_count", sa.Integer(), server_default="0", nullable=False),
        sa.Column(
            "mining_reward_catoshi",
            sa.BigInteger(),
            server_default="0",
            nullable=False,
        ),
        sa.Column(
            "game_reward_catoshi",
            sa.BigInteger(),
            server_default="0",
            nullable=False,
        ),
        sa.Column(
            "conditions_met_count",
            sa.Integer(),
            server_default="0",
            nullable=False,
        ),
        sa.Column("last_evaluated_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["referrer_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["referee_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["bonus_reviewed_by"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "referrer_user_id",
            "referee_user_id",
            name="uq_referrals_referrer_referee",
        ),
    )
    op.create_index("ix_referrals_referrer", "referrals", ["referrer_user_id"], unique=False)
    op.create_index("ix_referrals_referee", "referrals", ["referee_user_id"], unique=False)

    op.add_column(
        "earnings_ledger",
        sa.Column("referral_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_earnings_ledger_referral_id",
        "earnings_ledger",
        "referrals",
        ["referral_id"],
        ["id"],
    )

    # Backfill referral rows from users.referred_by
    conn.execute(
        sa.text(
            """
            INSERT INTO referrals (
              id, referrer_user_id, referee_user_id, referred_at,
              bonus_amount_catoshi, bonus_status
            )
            SELECT gen_random_uuid(), r.id, u.id, COALESCE(u.created_at, NOW()),
                   10000000, 'pending'
            FROM users u
            INNER JOIN users r ON lower(r.referral_code) = lower(u.referred_by)
            WHERE u.referred_by IS NOT NULL
              AND trim(u.referred_by) <> ''
              AND (u.is_deleted IS NULL OR u.is_deleted = false)
            ON CONFLICT ON CONSTRAINT uq_referrals_referrer_referee DO NOTHING;
            """
        )
    )

    op.execute(
        """
        ALTER TABLE referrals
        ADD CONSTRAINT fk_referrals_bonus_awarded_txn
        FOREIGN KEY (bonus_awarded_txn_id) REFERENCES earnings_ledger (id);
        """
    )


def downgrade() -> None:
    op.drop_constraint("fk_referrals_bonus_awarded_txn", "referrals", type_="foreignkey")
    op.drop_constraint("fk_earnings_ledger_referral_id", "earnings_ledger", type_="foreignkey")
    op.drop_column("earnings_ledger", "referral_id")
    op.drop_index("ix_referrals_referee", table_name="referrals")
    op.drop_index("ix_referrals_referrer", table_name="referrals")
    op.drop_table("referrals")
    # Cannot remove enum value safely in PostgreSQL without recreating type
