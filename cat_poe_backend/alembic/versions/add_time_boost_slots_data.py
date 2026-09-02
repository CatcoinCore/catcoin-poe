"""Persist per-base-session time boost slot state (JSON).

Revision ID: add_time_boost_slots_data
Revises: auth_hardening_001
Create Date: 2026-04-14

"""
from alembic import op
import sqlalchemy as sa

revision = "add_time_boost_slots_data"
down_revision = "auth_hardening_001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Column may already exist from update_time_boost_slots_schema.py / main.py startup.
    op.execute(
        sa.text(
            "ALTER TABLE public.mining_sessions "
            "ADD COLUMN IF NOT EXISTS time_boost_slots_data VARCHAR"
        )
    )


def downgrade() -> None:
    op.execute(
        sa.text(
            "ALTER TABLE public.mining_sessions "
            "DROP COLUMN IF EXISTS time_boost_slots_data"
        )
    )
