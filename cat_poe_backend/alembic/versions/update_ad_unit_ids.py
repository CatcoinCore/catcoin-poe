"""update_ad_unit_ids

Revision ID: update_ad_unit_ids
Revises: aee3cf226a4e
Create Date: 2026-02-10 16:30:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import text

# revision identifiers, used by Alembic.
revision = 'update_ad_unit_ids'
down_revision = 'aee3cf226a4e'
branch_labels = None
depends_on = None

def upgrade() -> None:
    # Google sample ad units (replace via admin UI or a follow-up migration for production).
    # Android rewarded test: .../5224354917; iOS rewarded test: .../1712485313
    op.execute(
        text(
            "UPDATE admin_config SET android_ad_unit_id = 'ca-app-pub-3940256099942544/5224354917', "
            "ios_ad_unit_id = 'ca-app-pub-3940256099942544/1712485313' WHERE id = 1"
        )
    )


def downgrade() -> None:
    # Revert to null or previous keys? 
    # Just leave as is, difficult to revert to 'unknown' previous state without backup
    pass
