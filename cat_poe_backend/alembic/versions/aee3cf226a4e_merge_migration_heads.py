"""merge_migration_heads

Revision ID: aee3cf226a4e
Revises: add_ad_views, add_backoff_config
Create Date: 2026-02-10 17:35:55.849693

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'aee3cf226a4e'
down_revision = ('add_ad_views', 'add_backoff_config')
branch_labels = None
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
