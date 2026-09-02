"""Add ad_views table

Revision ID: add_ad_views
Revises: split_version_control
Create Date: 2026-02-10 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_ad_views'
down_revision = 'split_version_control'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create ad_views table only if it doesn't exist
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    if 'ad_views' not in inspector.get_table_names():
        op.create_table('ad_views',
            sa.Column('transaction_id', sa.String(), nullable=False),
            sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('timestamp', sa.DateTime(), nullable=False),
            sa.Column('verified', sa.Boolean(), nullable=True),
            sa.Column('used_at', sa.DateTime(), nullable=True),
            sa.Column('created_at', sa.DateTime(), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('transaction_id')
        )


def downgrade() -> None:
    op.drop_table('ad_views')
