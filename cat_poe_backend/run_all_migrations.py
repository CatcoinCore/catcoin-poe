"""
Ordered SQL/Python migration scripts after Alembic.

Run via apply_db_migrations.sh (used by local_docker_smoke.sh and mirror_deploy.sh).
Add new schema steps here (or as Alembic revisions) so deploys stay consistent.
"""
import asyncio
import sys
import subprocess
from database import async_engine

# List of migration scripts to run in order
MIGRATIONS = [
    "update_x_credentials_schema.py",
    "update_missions_schema.py",
    "update_admin_schema.py",
    "update_fraud_schema.py",
    "add_suspicious_resolved_schema.py",
    "update_profile_config_schema.py",
    "update_x_community.py",
    "update_catoshi_schema.py",
    "update_user_country_badges_schema.py",
    "update_game_visibility_schema.py",
    "migrate_email_auth.py",
    "add_ad_columns.py",
    "update_extension_slots.py",
    "update_time_boost_slots_schema.py",
    "update_version.py",
    "update_social_verification_schema.py",
    "update_social_id_lock_schema.py",
    "update_password_reset_schema.py",
    "update_withdrawal_permissions_schema.py",
    "fix_null_suspicious.py",
    "fix_referral_case.py",
    "update_game_boosts_schema.py",
    "update_admin_game_ads_schema.py",
    "update_more_games_visibility.py",
    "migrate_game_cooldowns.py",
    "update_game_boost_matrix_schema.py",
    "update_special_bonus_schema.py",
    "update_reward_type_enum.py",
    "update_game_rewards_schema.py",
    "update_leaderboard_sort_schema.py",
    "update_app_ads_schema.py",
    "update_arrow_2048_games_schema.py",
    "update_global_push_message.py",
    "update_global_push_messages_column.py",
    "update_whats_new_json_column.py",
    "trim_whats_new_below_180.py",
    "seed_admin_game_config.py",
    "seed_admin_config_from_env.py",
]

async def run_all():
    print("🚀 Starting Unified Migration Process...")
    
    # Ensure the engine is clean before starting
    await async_engine.dispose()
    
    for script in MIGRATIONS:
        print(f"\n--- Running: {script} ---")
        # Use synchronous subprocess for simplicity within each migration step
        # and to avoid any async conflict within the same loop for separate engine disposals
        result = subprocess.run([sys.executable, script], capture_output=True, text=True)
        
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
            
        if result.returncode != 0:
            print(f"❌ Error in {script}. Stopping.")
            sys.exit(result.returncode)
            
    print("\n✅ All migrations complete!")

if __name__ == "__main__":
    asyncio.run(run_all())
