"""add_backoff_config

Revision ID: add_backoff_config
Revises: split_version_control
Create Date: 2026-02-06 09:30:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'add_backoff_config'
down_revision = 'split_version_control'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    columns = [c['name'] for c in inspector.get_columns('admin_config')]
    if 'verification_backoff_delays' not in columns:
        op.add_column('admin_config', sa.Column('verification_backoff_delays', sa.String(), nullable=True, server_default="[120, 180, 300, 420, 600]"))


def downgrade() -> None:
    op.drop_column('admin_config', 'verification_backoff_delays')
