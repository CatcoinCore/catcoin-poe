"""Split version control by platform

Revision ID: split_version_control
Revises: add_version_control
Create Date: 2026-02-06 06:10:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'split_version_control'
down_revision = 'add_version_control'
branch_labels = None
depends_on = None

def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    columns = [c['name'] for c in inspector.get_columns('admin_config')]

    # Android
    if 'latest_version_android' not in columns:
        op.add_column('admin_config', sa.Column('latest_version_android', sa.String(), server_default='1.0.0', nullable=True))
    if 'min_version_android' not in columns:
        op.add_column('admin_config', sa.Column('min_version_android', sa.String(), server_default='1.0.0', nullable=True))
    if 'update_url_android' not in columns:
        op.add_column('admin_config', sa.Column('update_url_android', sa.String(), server_default='https://play.google.com/store/apps/details?id=org.catcoin.cat', nullable=True))
    
    # iOS
    if 'latest_version_ios' not in columns:
        op.add_column('admin_config', sa.Column('latest_version_ios', sa.String(), server_default='1.0.0', nullable=True))
    if 'min_version_ios' not in columns:
        op.add_column('admin_config', sa.Column('min_version_ios', sa.String(), server_default='1.0.0', nullable=True))
    if 'update_url_ios' not in columns:
        op.add_column('admin_config', sa.Column('update_url_ios', sa.String(), server_default='https://apps.apple.com/app/id123456789', nullable=True))
    
    # Windows
    if 'latest_version_windows' not in columns:
        op.add_column('admin_config', sa.Column('latest_version_windows', sa.String(), server_default='1.0.0', nullable=True))
    if 'min_version_windows' not in columns:
        op.add_column('admin_config', sa.Column('min_version_windows', sa.String(), server_default='1.0.0', nullable=True))
    if 'update_url_windows' not in columns:
        op.add_column('admin_config', sa.Column('update_url_windows', sa.String(), server_default='https://catcoin.in/download', nullable=True))

    # Drop old columns ONLY if they exist
    if 'update_url' in columns:
        op.drop_column('admin_config', 'update_url')
    if 'min_app_version' in columns:
        op.drop_column('admin_config', 'min_app_version')
    if 'latest_app_version' in columns:
        op.drop_column('admin_config', 'latest_app_version')

def downgrade() -> None:
    # Restore old
    op.add_column('admin_config', sa.Column('latest_app_version', sa.String(), server_default='1.0.0', nullable=True))
    op.add_column('admin_config', sa.Column('min_app_version', sa.String(), server_default='1.0.0', nullable=True))
    op.add_column('admin_config', sa.Column('update_url', sa.String(), server_default='https://play.google.com/store/apps/details?id=org.catcoin.cat', nullable=True))

    # Drop new
    op.drop_column('admin_config', 'update_url_windows')
    op.drop_column('admin_config', 'min_version_windows')
    op.drop_column('admin_config', 'latest_version_windows')
    op.drop_column('admin_config', 'update_url_ios')
    op.drop_column('admin_config', 'min_version_ios')
    op.drop_column('admin_config', 'latest_version_ios')
    op.drop_column('admin_config', 'update_url_android')
    op.drop_column('admin_config', 'min_version_android')
    op.drop_column('admin_config', 'latest_version_android')
