"""Add daily ledger aggregation

Revision ID: add_daily_ledger
Revises: 
Create Date: 2025-11-30 07:20:00

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_daily_ledger'
down_revision = None
depends_on = None


def upgrade():
    # Add aggregation_date to earnings_ledger (nullable for non-mining)
    op.add_column('earnings_ledger',
        sa.Column('aggregation_date', sa.Date(), nullable=True))
    
    # Add description for non-mining transactions
    op.add_column('earnings_ledger',
        sa.Column('description', sa.String(500), nullable=True))
    
    # Add WITHDRAWAL to RewardType enum
    # Note: PostgreSQL enum alterations require special handling
    op.execute("ALTER TYPE rewardtype ADD VALUE IF NOT EXISTS 'WITHDRAWAL'")
    
    # Create index for mining lookups
    op.create_index(
        'idx_user_date_type',
        'earnings_ledger',
        ['user_id', 'aggregation_date', 'reward_type']
    )
    
    # Create junction table for ledger-session mappings
    op.create_table(
        'ledger_session_mappings',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('ledger_entry_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('session_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('session_contribution', sa.Float(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['ledger_entry_id'], ['earnings_ledger.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['session_id'], ['mining_sessions.id'], ondelete='CASCADE'),
        sa.UniqueConstraint('session_id', name='_unique_session_uc')
    )
    
    # Add completion tracking to mining_sessions
    op.add_column('mining_sessions',
        sa.Column('completed_at', sa.DateTime(), nullable=True))
    op.add_column('mining_sessions',
        sa.Column('ledger_entry_id', postgresql.UUID(as_uuid=True), nullable=True))
    op.create_foreign_key(
        'fk_session_ledger',
        'mining_sessions', 'earnings_ledger',
        ['ledger_entry_id'], ['id'],
        ondelete='SET NULL'
    )


def downgrade():
    # Remove foreign key and columns from mining_sessions
    op.drop_constraint('fk_session_ledger', 'mining_sessions', type_='foreignkey')
    op.drop_column('mining_sessions', 'ledger_entry_id')
    op.drop_column('mining_sessions', 'completed_at')
    
    # Drop junction table
    op.drop_table('ledger_session_mappings')
    
    # Remove index
    op.drop_index('idx_user_date_type', 'earnings_ledger')
    
    # Remove columns from earnings_ledger
    op.drop_column('earnings_ledger', 'description')
    op.drop_column('earnings_ledger', 'aggregation_date')
    
    # Note: Cannot easily remove enum value in PostgreSQL
    # Would require recreating the enum type
