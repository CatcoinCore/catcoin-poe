"""Add total_earnings and config fields

Revision ID: add_total_earnings_and_config
Revises: add_game_tables
Create Date: 2026-03-13 22:40:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

# revision identifiers, used by Alembic.
revision = 'add_total_earnings_and_config'
down_revision = 'add_game_tables'
branch_labels = None
depends_on = None

def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names(schema="public"))

    # 1. Users table
    if 'users' in tables:
        columns = [c['name'] for c in inspector.get_columns('users', schema='public')]
        if 'total_earnings' not in columns:
            op.add_column('users', sa.Column('total_earnings', sa.Float(), server_default='0.0', nullable=True))
            
            # Backfill total_earnings from earnings_ledger
            op.execute("""
                UPDATE users 
                SET total_earnings = (
                    SELECT COALESCE(SUM(amount), 0)
                    FROM earnings_ledger
                    WHERE earnings_ledger.user_id = users.id
                    AND amount > 0
                )
            """)

    # 2. Admin Config table
    if 'admin_config' in tables:
        columns = [c['name'] for c in inspector.get_columns('admin_config', schema='public')]
        admin_cols = {
            "use_manual_cat_price": sa.Boolean(),
            "manual_cat_price_usdt": sa.Integer(),
            "coingecko_coin_id": sa.String(),
            "catoshi_yield_percentage": sa.Float(),
            "referral_boost_percentage": sa.Float(),
            "max_active_referrers": sa.Integer()
        }
        for col, type_ in admin_cols.items():
            if col not in columns:
                op.add_column('admin_config', sa.Column(col, type_, nullable=True))

    # 3. Mining Sessions table
    if 'mining_sessions' in tables:
        columns = [c['name'] for c in inspector.get_columns('mining_sessions', schema='public')]
        if 'reward_y' not in columns:
            op.add_column('mining_sessions', sa.Column('reward_y', sa.Integer(), server_default='0', nullable=True))
        if 'reward_t' not in columns:
            op.add_column('mining_sessions', sa.Column('reward_t', sa.Integer(), server_default='1', nullable=True))

def downgrade() -> None:
    # Note: Downgrade drops columns regardless of whether they existed before the migration
    # Use with caution in production.
    op.drop_column('mining_sessions', 'reward_t')
    op.drop_column('mining_sessions', 'reward_y')
    op.drop_column('admin_config', 'max_active_referrers')
    op.drop_column('admin_config', 'referral_boost_percentage')
    op.drop_column('admin_config', 'catoshi_yield_percentage')
    op.drop_column('admin_config', 'coingecko_coin_id')
    op.drop_column('admin_config', 'manual_cat_price_usdt')
    op.drop_column('admin_config', 'use_manual_cat_price')
    op.drop_column('users', 'total_earnings')
