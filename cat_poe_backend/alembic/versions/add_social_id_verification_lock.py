"""Add social ID verified, locked, old columns and verification audit table

Revision ID: add_social_id_verification_lock
Revises: add_total_earnings_and_config
Create Date: 2026-04-06 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect
from sqlalchemy.dialects import postgresql

revision = "add_social_id_verification_lock"
down_revision = "add_total_earnings_and_config"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names(schema="public"))

    if "users" in tables:
        columns = {c["name"] for c in inspector.get_columns("users", schema="public")}
        additions = [
            ("discord_id_verified", sa.Boolean(), "false"),
            ("discord_id_locked", sa.Boolean(), "false"),
            ("discord_id_old", sa.String(), None),
            ("telegram_id_verified", sa.Boolean(), "false"),
            ("telegram_id_locked", sa.Boolean(), "false"),
            ("telegram_id_old", sa.String(), None),
            ("x_id_verified", sa.Boolean(), "false"),
            ("x_id_locked", sa.Boolean(), "false"),
            ("x_id_old", sa.String(), None),
            ("facebook_id_verified", sa.Boolean(), "false"),
            ("facebook_id_locked", sa.Boolean(), "false"),
            ("facebook_id_old", sa.String(), None),
            ("whatsapp_id_verified", sa.Boolean(), "false"),
            ("whatsapp_id_locked", sa.Boolean(), "false"),
            ("whatsapp_id_old", sa.String(), None),
        ]
        for name, col_type, default in additions:
            if name not in columns:
                kw = {"nullable": True}
                if default is not None:
                    kw["server_default"] = default
                op.add_column("users", sa.Column(name, col_type, **kw))

        for platform in ("discord", "telegram", "x", "facebook", "whatsapp"):
            op.execute(
                f"UPDATE users SET {platform}_id_locked = TRUE "
                f"WHERE {platform}_id_verified = TRUE"
            )

    if "social_verification_audit" not in tables:
        op.create_table(
            "social_verification_audit",
            sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column("action", sa.String(length=64), nullable=False),
            sa.Column("platform", sa.String(length=32), nullable=True),
            sa.Column("detail", sa.String(length=1000), nullable=True),
            sa.Column("amount", sa.Float(), nullable=True),
            sa.Column("created_at", sa.DateTime(), nullable=True),
            sa.ForeignKeyConstraint(
                ["user_id"], ["users.id"], ondelete="CASCADE"
            ),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(
            "idx_social_verification_audit_user",
            "social_verification_audit",
            ["user_id"],
            unique=False,
        )


def downgrade() -> None:
    op.drop_index(
        "idx_social_verification_audit_user",
        table_name="social_verification_audit",
    )
    op.drop_table("social_verification_audit")

    for name in (
        "whatsapp_id_old",
        "whatsapp_id_locked",
        "whatsapp_id_verified",
        "facebook_id_old",
        "facebook_id_locked",
        "facebook_id_verified",
        "x_id_old",
        "x_id_locked",
        "x_id_verified",
        "telegram_id_old",
        "telegram_id_locked",
        "telegram_id_verified",
        "discord_id_old",
        "discord_id_locked",
        "discord_id_verified",
    ):
        op.drop_column("users", name)
