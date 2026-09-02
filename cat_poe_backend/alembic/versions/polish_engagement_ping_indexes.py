"""Index last_active_at and ping dedupe lookups.

Revision ID: polish_engagement_ping_indexes
Revises: add_user_ping_notifications
Create Date: 2026-04-16

"""
from alembic import op
import sqlalchemy as sa

revision = "polish_engagement_ping_indexes"
down_revision = "add_user_ping_notifications"
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)

    ix_users = "ix_users_last_active_at_engagement"
    if ix_users not in {i["name"] for i in inspector.get_indexes("users", schema="public")}:
        op.create_index(ix_users, "users", ["last_active_at"], unique=False)

    ping_indexes = {i["name"] for i in inspector.get_indexes("user_ping_notifications", schema="public")}
    dedupe_ix = "idx_user_ping_dedupe_lookup"
    if dedupe_ix not in ping_indexes:
        op.create_index(
            dedupe_ix,
            "user_ping_notifications",
            ["recipient_user_id", "kind", "sender_user_id", "created_at"],
            unique=False,
        )


def downgrade() -> None:
    op.drop_index("idx_user_ping_dedupe_lookup", table_name="user_ping_notifications")
    op.drop_index("ix_users_last_active_at_engagement", table_name="users")
