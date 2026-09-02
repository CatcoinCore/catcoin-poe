"""add account deletion tables

Revision ID: add_account_deletion
Revises: add_refresh_tokens
Create Date: 2025-12-30 14:15:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_account_deletion'
down_revision = 'initial_schema'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    columns = [c['name'] for c in inspector.get_columns('users')]
    
    # Add columns to users table only if they don't exist
    if 'is_deleted' not in columns:
        op.add_column('users', sa.Column('is_deleted', sa.Boolean(), server_default='false', nullable=True))
    if 'deleted_at' not in columns:
        op.add_column('users', sa.Column('deleted_at', sa.DateTime(), nullable=True))

    # Create deleted_identities table only if it doesn't exist
    if not inspector.has_table('deleted_identities'):
        op.create_table('deleted_identities',
            sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('identity_hash', sa.String(), nullable=False),
            sa.Column('total_rewards', sa.Float(), server_default='0.0', nullable=True),
            sa.Column('deleted_at', sa.DateTime(), nullable=True),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_deleted_identities_identity_hash'), 'deleted_identities', ['identity_hash'], unique=True)


def downgrade() -> None:
    op.drop_index(op.f('ix_deleted_identities_identity_hash'), table_name='deleted_identities')
    op.drop_table('deleted_identities')
    op.drop_column('users', 'deleted_at')
    op.drop_column('users', 'is_deleted')
