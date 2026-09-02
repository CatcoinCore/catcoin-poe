"""Add game_sessions and game_rewards tables

Revision ID: add_game_tables
Revises: update_ad_unit_ids
Create Date: 2026-03-06 22:50:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_game_tables'
down_revision = 'update_ad_unit_ids'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    tables = inspector.get_table_names()

    # Create game_sessions table only if it doesn't exist
    if 'game_sessions' not in tables:
        op.create_table('game_sessions',
            sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('session_token', sa.String(), nullable=False),
            sa.Column('start_time', sa.DateTime(), nullable=True),
            sa.Column('end_time', sa.DateTime(), nullable=True),
            sa.Column('score', sa.Integer(), server_default='0', nullable=True),
            sa.Column('coins_collected', sa.Integer(), server_default='0', nullable=True),
            sa.Column('distance_meters', sa.Integer(), server_default='0', nullable=True),
            sa.Column('validated', sa.Boolean(), server_default='false', nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('id'),
        )
        op.create_index('idx_game_sessions_user', 'game_sessions', ['user_id'])
        op.create_index(op.f('ix_game_sessions_session_token'), 'game_sessions', ['session_token'], unique=True)

    # Create game_rewards table only if it doesn't exist
    if 'game_rewards' not in tables:
        op.create_table('game_rewards',
            sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('session_id', postgresql.UUID(as_uuid=True), nullable=False),
            sa.Column('reward_catoshi', sa.Integer(), nullable=False),
            sa.Column('created_at', sa.DateTime(), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.ForeignKeyConstraint(['session_id'], ['game_sessions.id'], ),
            sa.PrimaryKeyConstraint('id'),
        )
        op.create_index('idx_game_rewards_user', 'game_rewards', ['user_id'])


def downgrade() -> None:
    op.drop_index('idx_game_rewards_user', table_name='game_rewards')
    op.drop_table('game_rewards')
    op.drop_index(op.f('ix_game_sessions_session_token'), table_name='game_sessions')
    op.drop_index('idx_game_sessions_user', table_name='game_sessions')
    op.drop_table('game_sessions')
