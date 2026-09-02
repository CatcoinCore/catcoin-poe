"""refresh token family_id; separate password reset OTP columns

Revision ID: auth_hardening_001
Revises: (set down_revision to current head - check)
Create Date: 2026-04-08

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "auth_hardening_001"
down_revision = "add_social_id_verification_lock"
branch_labels = None
depends_on = None

_SCHEMA = "public"


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)

    user_cols = {c["name"] for c in inspector.get_columns("users", schema=_SCHEMA)}
    if "password_reset_code" not in user_cols:
        op.add_column(
            "users",
            sa.Column("password_reset_code", sa.String(length=6), nullable=True),
            schema=_SCHEMA,
        )
    if "password_reset_expires" not in user_cols:
        op.add_column(
            "users",
            sa.Column("password_reset_expires", sa.DateTime(), nullable=True),
            schema=_SCHEMA,
        )

    rt_cols = {c["name"] for c in inspector.get_columns("refresh_tokens", schema=_SCHEMA)}
    if "family_id" not in rt_cols:
        op.add_column(
            "refresh_tokens",
            sa.Column("family_id", postgresql.UUID(as_uuid=True), nullable=True),
            schema=_SCHEMA,
        )
        op.execute(sa.text("UPDATE refresh_tokens SET family_id = id WHERE family_id IS NULL"))
        op.alter_column(
            "refresh_tokens",
            "family_id",
            existing_type=postgresql.UUID(as_uuid=True),
            nullable=False,
            schema=_SCHEMA,
        )
    else:
        op.execute(sa.text("UPDATE refresh_tokens SET family_id = id WHERE family_id IS NULL"))
        op.alter_column(
            "refresh_tokens",
            "family_id",
            existing_type=postgresql.UUID(as_uuid=True),
            nullable=False,
            schema=_SCHEMA,
        )

    existing_ix = {
        ix["name"] for ix in inspector.get_indexes("refresh_tokens", schema=_SCHEMA)
    }
    if "ix_refresh_tokens_family_id" not in existing_ix:
        op.create_index(
            "ix_refresh_tokens_family_id",
            "refresh_tokens",
            ["family_id"],
            unique=False,
            schema=_SCHEMA,
        )


def downgrade() -> None:
    op.drop_index(
        "ix_refresh_tokens_family_id",
        table_name="refresh_tokens",
        schema=_SCHEMA,
    )
    op.drop_column("refresh_tokens", "family_id", schema=_SCHEMA)
    op.drop_column("users", "password_reset_expires", schema=_SCHEMA)
    op.drop_column("users", "password_reset_code", schema=_SCHEMA)
