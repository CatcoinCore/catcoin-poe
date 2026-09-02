"""Add version control fields

Revision ID: add_version_control
Revises: add_wallet_source
Create Date: 2026-02-04 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_version_control'
down_revision = 'add_wallet_source'
branch_labels = None
depends_on = None

def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    columns = [c['name'] for c in inspector.get_columns('admin_config')]
    
    if 'latest_app_version' not in columns:
        op.add_column('admin_config', sa.Column('latest_app_version', sa.String(), server_default='1.0.0', nullable=True))
    if 'min_app_version' not in columns:
        op.add_column('admin_config', sa.Column('min_app_version', sa.String(), server_default='1.0.0', nullable=True))
    if 'update_url' not in columns:
        op.add_column('admin_config', sa.Column('update_url', sa.String(), server_default='https://play.google.com/store/apps/details?id=org.catcoin.cat', nullable=True))

def downgrade() -> None:
    op.drop_column('admin_config', 'update_url')
    op.drop_column('admin_config', 'min_app_version')
    op.drop_column('admin_config', 'latest_app_version')
