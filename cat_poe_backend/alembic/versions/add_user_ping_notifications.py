"""user_ping_notifications for referral/admin nudges

Revision ID: add_user_ping_notifications
Revises: add_time_boost_slots_data
Create Date: 2026-04-16

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "add_user_ping_notifications"
down_revision = "add_time_boost_slots_data"
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    tables = inspector.get_table_names()
    if "user_ping_notifications" in tables:
        return
    op.create_table(
        "user_ping_notifications",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("recipient_user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("sender_user_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("kind", sa.String(length=64), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["recipient_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["sender_user_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "idx_user_ping_recipient_created",
        "user_ping_notifications",
        ["recipient_user_id", "created_at"],
    )
    op.create_index("idx_user_ping_kind", "user_ping_notifications", ["kind"])


def downgrade() -> None:
    op.drop_index("idx_user_ping_kind", table_name="user_ping_notifications")
    op.drop_index("idx_user_ping_recipient_created", table_name="user_ping_notifications")
    op.drop_table("user_ping_notifications")
