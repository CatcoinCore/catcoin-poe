import os
import zipfile
from datetime import datetime
import argparse

def create_deployment_package(include_assets=False):
    # Configuration
    OUTPUT_FILENAME = f"backend_deploy_{datetime.now().strftime('%Y%m%d_%H%M%S')}.zip"
    SOURCE_DIR = os.getcwd()
    
    # Allowlist - Folders to include (recursive)
    INCLUDE_DIRS = [
        'alembic',
        'routers',
        'services',
        'utils',
        'templates',
        'migrations'
    ]
    
    if include_assets:
        print("💡 Asset inclusion active. This will increase package size.")
        INCLUDE_DIRS.append('static')
    else:
        print("ℹ️ Skipping 'static' folder (use --assets to include)")
    
    # Allowlist - Files to include (exact match)
    INCLUDE_FILES = [
        # ... (keep same list)
        'main.py', 'models.py', 'schemas.py', 'database.py', 'config.py', 'auth.py',
        'admin_config_defaults.py', 'seed_admin_game_config.py',
        'seed_admin_config_from_env.py', 
        'requirements.txt', 'Dockerfile', 'docker-compose.prod.yml', 'deploy.sh', 
        'nginx.conf', 'alembic.ini', 'create_root_user.py', "seed_missions.py",
        "update_admin_schema.py", "update_missions_schema.py", "update_user_country_badges_schema.py",
        "update_x_config_schema.py", 'migrate_email_auth.py', 'add_ad_columns.py',
        'update_extension_slots.py', 'update_time_boost_slots_schema.py',
        'check_db_config.py', 'verify_deployment.py',
        'logger_config.py', 'update_fraud_schema.py', 'post_to_community.py',
        'update_x_credentials_schema.py', 'test_x_integration.py', 'backup_db.sh',
        'restore_db.sh', 'clean_rebuild.sh', 'clean_rebuild.ps1', 'check_db_schema.py',
        'debug_query.py', 'update_profile_config_schema.py', 'update_x_community.py',
        'activate_ads.py', 'debug_x_config.py', 'fix_x_mission.py', 'update_catoshi_schema.py',
        'test_api.py', 'fix_catcoin_id.py', 'test_coingecko.py', 'update_game_visibility_schema.py',
        'update_social_verification_schema.py', 'update_social_id_lock_schema.py',
        'update_password_reset_schema.py',
        'update_withdrawal_permissions_schema.py',
        'fix_null_suspicious.py', 'fix_referral_case.py', 'fix_missing_user_columns.py',
        'migrate_users_v2.py', 'update_app_ads_schema.py', 'update_game_boosts_schema.py',
        'update_admin_game_ads_schema.py',
        'DEPLOYMENT.md', 'QUICK_REFERENCE.md', 'README.md',
        'gen_manifest.py', 'run_all_migrations.py', 'script_env.py', 'update_version.py',
        # --- Missing migration scripts added below ---
        'add_suspicious_resolved_schema.py',
        'update_more_games_visibility.py',
        'migrate_game_cooldowns.py',
        'update_game_boost_matrix_schema.py',
        'update_special_bonus_schema.py',
        'update_reward_type_enum.py',
        'update_game_rewards_schema.py',
        'update_leaderboard_sort_schema.py',
        # --- Mirror deploy files ---
        'mirror_deploy.sh',
        'apply_db_migrations.sh',
        'local_docker_smoke.sh',
        'generate_dev_ssl.sh',
        'upstream.inc',
    ]

    print(f"📦 Creating deployment package: {OUTPUT_FILENAME}")
    
    with zipfile.ZipFile(OUTPUT_FILENAME, 'w', zipfile.ZIP_DEFLATED) as zip_ref:
        # 1. Add specific root files
        for filename in INCLUDE_FILES:
            file_path = os.path.join(SOURCE_DIR, filename)
            if os.path.exists(file_path):
                zip_ref.write(file_path, filename)

        # 2. Add directories
        for dirname in INCLUDE_DIRS:
            dir_path = os.path.join(SOURCE_DIR, dirname)
            if os.path.exists(dir_path):
                print(f"  + Adding directory: {dirname}/")
                for root, _, files in os.walk(dir_path):
                    if any(exclude in root for exclude in ['__pycache__', '.git']):
                        continue
                    for file in files:
                        if file.endswith('.pyc') or file == '.DS_Store':
                            continue
                        abs_path = os.path.join(root, file)
                        rel_path = os.path.relpath(abs_path, SOURCE_DIR)
                        # Silent addition to prevent "freeze" feel
                        zip_ref.write(abs_path, rel_path)

    print("\n✅ Package created successfully!")
    print(f"Filename: {OUTPUT_FILENAME}")
    print(f"Final size: {os.path.getsize(OUTPUT_FILENAME) / 1024 / 1024:.2f} MB")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--assets', action='store_true', help='Include static assets')
    args = parser.parse_args()
    create_deployment_package(include_assets=args.assets)
