# Master Rebuild Script for Windows (PowerShell)
# Requires DB_PASSWORD in environment or in a `.env` file in this directory.

if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $val = $matches[2].Trim().Trim('"').Trim("'")
            Set-Item -Path "env:$name" -Value $val
        }
    }
}

if (-not $env:DB_PASSWORD) {
    Write-Host "DB_PASSWORD is not set. Add it to .env (see .env.example)." -ForegroundColor Red
    exit 1
}

Write-Host "WARNING: This script will backup your database, delete all containers/volumes, rebuild the backend, and restore the data." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to cancel or wait 5 seconds to proceed..."
Start-Sleep -Seconds 5

New-Item -ItemType Directory -Force -Path ".\backups" | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = ".\backups\catcoin_backup_$timestamp.sql"

Write-Host "Step 1: Backing up database to $backupFile..." -ForegroundColor Cyan
docker compose -f docker-compose.prod.yml exec -T -e "PGPASSWORD=$($env:DB_PASSWORD)" postgres sh -c "pg_dump -U catpoe catcoin_poe" | Set-Content -Path $backupFile -Encoding utf8

if ($LASTEXITCODE -ne 0) {
    Write-Host "Backup failed! Aborting to prevent data loss." -ForegroundColor Red
    exit 1
}

if ((Get-Item $backupFile).Length -eq 0) {
    Write-Host "Backup failed (Empty file)!" -ForegroundColor Red
    Remove-Item $backupFile
    exit 1
}

Write-Host "Backup successful." -ForegroundColor Green

Write-Host "Step 2: Stopping containers and removing volumes..." -ForegroundColor Cyan
docker compose -f docker-compose.prod.yml down -v

Write-Host "Step 3: Rebuilding backend image (no cache)..." -ForegroundColor Cyan
docker compose -f docker-compose.prod.yml build --no-cache backend

Write-Host "Step 4: Starting services..." -ForegroundColor Cyan
docker compose -f docker-compose.prod.yml up -d

Write-Host "Waiting for database to initialize (10 seconds)..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

Write-Host "Step 5: Restoring database..." -ForegroundColor Cyan

docker compose -f docker-compose.prod.yml exec -T -e "PGPASSWORD=$($env:DB_PASSWORD)" postgres sh -c 'psql -U catpoe -d template1 -c "DROP DATABASE IF EXISTS \"catcoin_poe\" WITH (FORCE);"'
docker compose -f docker-compose.prod.yml exec -T -e "PGPASSWORD=$($env:DB_PASSWORD)" postgres sh -c 'psql -U catpoe -d template1 -c "CREATE DATABASE \"catcoin_poe\";"'

Get-Content $backupFile -Raw | docker compose -f docker-compose.prod.yml exec -T -e "PGPASSWORD=$($env:DB_PASSWORD)" postgres sh -c "psql -U catpoe -d catcoin_poe"

Write-Host "Step 6: Applying migration script..." -ForegroundColor Cyan
docker compose -f docker-compose.prod.yml run --rm backend python update_x_credentials_schema.py

if ($LASTEXITCODE -eq 0) {
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Clean rebuild and restore complete!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
} else {
    Write-Host "Process completed with errors (check log above)." -ForegroundColor Yellow
}
