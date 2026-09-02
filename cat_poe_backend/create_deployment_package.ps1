param(
    [Parameter(Mandatory=$false)]
    [switch]$IncludeAssets = $false
)

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = "backend_deploy_$Timestamp.zip"
$StagingDir = "D:\temp_deploy_staging_$Timestamp"

# Base dirs for code
$IncludeDirs = @("alembic", "routers", "services", "utils", "templates", "migrations")

if ($IncludeAssets) {
    Write-Host "[!] Asset inclusion active. This will take significantly longer." -ForegroundColor Yellow
    $IncludeDirs += "static"
} else {
    Write-Host "[*] Skipping large 'static' folder (use -IncludeAssets to include)" -ForegroundColor Blue
}

$IncludeFiles = @(
    "main.py", "models.py", "schemas.py", "database.py", "config.py",
    "auth.py",
    "admin_config_defaults.py", "seed_admin_game_config.py", "seed_admin_config_from_env.py",
    "requirements.txt", "Dockerfile", "docker-compose.prod.yml", "deploy.sh",
    "nginx.conf", "alembic.ini", "create_root_user.py", "seed_missions.py",
    "update_admin_schema.py", "update_missions_schema.py", "update_user_country_badges_schema.py",
    "update_x_config_schema.py", "migrate_email_auth.py", "add_ad_columns.py",
    "update_extension_slots.py", "update_time_boost_slots_schema.py",
    "check_db_config.py", "verify_deployment.py",
    "logger_config.py", "update_fraud_schema.py", "post_to_community.py",
    "update_x_credentials_schema.py", "test_x_integration.py", "backup_db.sh",
    "restore_db.sh", "clean_rebuild.sh", "clean_rebuild.ps1", "check_db_schema.py",
    "debug_query.py", "update_profile_config_schema.py", "update_x_community.py",
    "activate_ads.py", "debug_x_config.py", "fix_x_mission.py", "update_catoshi_schema.py",
    "test_api.py", "fix_catcoin_id.py", "test_coingecko.py", "update_game_visibility_schema.py",
    "update_social_verification_schema.py", "update_social_id_lock_schema.py",
    "update_password_reset_schema.py",
    "update_withdrawal_permissions_schema.py",
    "fix_null_suspicious.py", "fix_referral_case.py", "fix_missing_user_columns.py",
    "migrate_users_v2.py", "update_app_ads_schema.py", "update_game_boosts_schema.py",
    "update_admin_game_ads_schema.py",
    "DEPLOYMENT.md", "QUICK_REFERENCE.md", "README.md",
    ".env.example", ".env.production.example", "DEPLOY_README.txt",
    "gen_manifest.py", "run_all_migrations.py", "script_env.py", "update_version.py",
    "add_suspicious_resolved_schema.py",
    "update_more_games_visibility.py",
    "migrate_game_cooldowns.py",
    "update_game_boost_matrix_schema.py",
    "update_special_bonus_schema.py",
    "update_reward_type_enum.py",
    "update_game_rewards_schema.py",
    "update_leaderboard_sort_schema.py",
    "mirror_deploy.sh",
    "apply_db_migrations.sh",
    "local_docker_smoke.sh",
    "generate_dev_ssl.sh",
    "upstream.inc",
    "ssl/README.md"
)

Write-Host "Creating deployment package: $OutputFile"

# Create a staging directory on D: to avoid cross-drive issues if any
if (Test-Path $StagingDir) { Remove-Item $StagingDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $StagingDir -Force

$ProjectRoot = $PSScriptRoot

# Copy files (create parent dirs for paths like ssl/README.md)
foreach ($File in $IncludeFiles) {
    if (Test-Path "$ProjectRoot\$File") {
        Write-Host "  + Adding file: $File"
        $destPath = Join-Path $StagingDir $File
        $destParent = Split-Path $destPath -Parent
        if (-not (Test-Path $destParent)) {
            New-Item -ItemType Directory -Path $destParent -Force | Out-Null
        }
        Copy-Item -Path "$ProjectRoot\$File" -Destination $destPath -Force -ErrorAction SilentlyContinue
    }
}

# Copy directories
foreach ($Dir in $IncludeDirs) {
    if (Test-Path "$ProjectRoot\$Dir") {
        Write-Host "  + Adding directory: $Dir/"
        $DestDir = New-Item -ItemType Directory -Path "$StagingDir\$Dir" -Force
        Copy-Item -Path "$ProjectRoot\$Dir\*" -Destination "$DestDir" -Recurse -Force -Exclude "__pycache__", ".git", "*.pyc" -ErrorAction SilentlyContinue
    }
}

Write-Host "Waiting for file handles to release..."
Start-Sleep -Seconds 2

# Create zip with retry
$RetryCount = 3
$Success = $false
for ($i = 0; $i -lt $RetryCount; $i++) {
    try {
        Compress-Archive -Path "$StagingDir\*" -DestinationPath "$ProjectRoot\$OutputFile" -Force -ErrorAction Stop
        $Success = $true
        break
    } catch {
        Write-Host "  Retrying zip ($i)..."
        Start-Sleep -Seconds 5
    }
}

# Cleanup Staging
Remove-Item -Path "$StagingDir" -Recurse -Force -ErrorAction SilentlyContinue

if ($Success) {
    Write-Host "Package created successfully!"
    Write-Host "Filename: $OutputFile"
    $ZipSize = (Get-Item "$ProjectRoot\$OutputFile").Length / 1MB
    Write-Host "Final size: $ZipSize MB"
} else {
    Write-Host "Failed to create package after retries."
    exit 1
}
