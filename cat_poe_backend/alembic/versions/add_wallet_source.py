"""Add source column to wallets

Revision ID: add_wallet_source
Revises: add_account_deletion
Create Date: 2026-01-24 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_wallet_source'
down_revision = 'add_account_deletion'
branch_labels = None
depends_on = None

# Define the enum type
wallet_source_enum = sa.Enum('GENERATED', 'IMPORTED', 'MANUAL', name='walletsource')

def upgrade() -> None:
    # Check if the column already exists
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    columns = [c['name'] for c in inspector.get_columns('wallets')]
    
    if 'source' not in columns:
        # Create the enum type first
        wallet_source_enum.create(conn, checkfirst=True)
        
        # Add the column with default 'MANUAL'
        op.add_column('wallets', sa.Column('source', wallet_source_enum, nullable=True))
        
        # Update existing rows to 'MANUAL'
        op.execute("UPDATE wallets SET source = 'MANUAL'")
    else:
        # Column already exists, but ensure the enum is there just in case
        wallet_source_enum.create(conn, checkfirst=True)
    
    # Now alter column to be non-nullable if desired, or leave nullable with server default.
    # Let's set a server default for future
    op.alter_column('wallets', 'source', server_default='MANUAL')


def downgrade() -> None:
    op.drop_column('wallets', 'source')
    wallet_source_enum.drop(op.get_bind(), checkfirst=True)
