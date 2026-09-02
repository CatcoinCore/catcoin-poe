from fastapi import FastAPI, Request, Depends, HTTPException, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import HTMLResponse, RedirectResponse, PlainTextResponse, JSONResponse
import logging
from sqlalchemy.ext.asyncio import AsyncSession
import database
import re
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from fastapi.openapi.docs import get_swagger_ui_html, get_redoc_html
from database import async_engine, Base
from routers import auth as auth_router, mining, missions, wallets, admin, config_utility, callbacks, leaderboard, game
from routers import referrals as referrals_router, referral_bonus_admin as referral_bonus_admin_router
from routers import diagnostics as diagnostics_router
from datetime import datetime
import asyncio
import auth
from logger_config import setup_logging
from config import settings
from jobs.referral_reconciliation import run_referral_reconciliation_periodically
from services.unverified_user_cleanup import run_unverified_cleanup_periodically
import secrets
import models
from fastapi.staticfiles import StaticFiles
import os
import json
from html import escape
from pathlib import Path

# Background task handles (cancelled on shutdown)
_referral_reconciliation_task: asyncio.Task | None = None
_unverified_cleanup_task: asyncio.Task | None = None

# Setup logging before app starts
setup_logging()

app = FastAPI(
    title="Catcoin PoE Backend",
    docs_url=None,  # Disable default docs
    redoc_url=None, # Disable default redoc
    openapi_url=None # Disable default openapi.json
)

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Log validation errors to the console and return detailed error info"""
    logging.error(f"Validation error for {request.url}: {exc.errors()}")
    content: dict = {"detail": exc.errors()}
    if settings.ENVIRONMENT == "development":
        content["body"] = str(exc.body) if hasattr(exc, "body") else None
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=content,
    )

# Ensure static directory exists
static_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")
os.makedirs(os.path.join(static_dir, "game", "runner"), exist_ok=True)

# Mount static files
app.mount("/static", StaticFiles(directory=static_dir), name="static")

@app.get("/debug/static")
async def debug_static():
    if settings.ENVIRONMENT != "development":
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)
    files = []
    for root, dirs, f in os.walk(static_dir):
        for file in f:
            files.append(os.path.relpath(os.path.join(root, file), static_dir))
    return {"static_dir": static_dir, "files": files}

# Basic Auth Security
security = HTTPBasic()

def get_current_username_docs(credentials: HTTPBasicCredentials = Depends(security)):
    correct_username = secrets.compare_digest(credentials.username, settings.DOCS_USER)
    correct_password = secrets.compare_digest(credentials.password, settings.DOCS_PASSWORD)
    if not (correct_username and correct_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Basic"},
        )
    return credentials.username

@app.get("/docs", include_in_schema=False)
async def get_swagger_documentation(username: str = Depends(get_current_username_docs)):
    return get_swagger_ui_html(openapi_url="/openapi.json", title="docs")

@app.get("/redoc", include_in_schema=False)
async def get_redoc_documentation(username: str = Depends(get_current_username_docs)):
    return get_redoc_html(openapi_url="/openapi.json", title="docs")

@app.get("/openapi.json", include_in_schema=False)
async def openapi(username: str = Depends(get_current_username_docs)):
    from fastapi.openapi.utils import get_openapi
    return get_openapi(title=app.title, version=app.version, routes=app.routes)

app.include_router(auth_router.router)
app.include_router(mining.router)
app.include_router(missions.router)
app.include_router(wallets.router)
app.include_router(admin.router)
app.include_router(config_utility.router)
app.include_router(callbacks.router)
app.include_router(leaderboard.router)
app.include_router(game.router)
app.include_router(referrals_router.router)
app.include_router(referral_bonus_admin_router.router)
app.include_router(diagnostics_router.router)

def generate_manifest():
    static_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static", "game", "runner")
    if not os.path.exists(static_dir):
        return
        
    assets = []
    for root, dirs, files in os.walk(static_dir):
        for file in files:
            if file == "manifest.json":
                continue
            
            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, static_dir)
            rel_path = rel_path.replace(os.sep, "/")
            
            assets.append({
                "path": rel_path,
                "size": os.path.getsize(full_path)
            })
    
    manifest_path = os.path.join(static_dir, "manifest.json")
    with open(manifest_path, "w") as f:
        json.dump({"assets": assets}, f, indent=4)
    print(f"Generated asset manifest with {len(assets)} files")

@app.post("/admin/migrate-catoshi")
async def migrate_data_to_catoshi(
    user: models.User = Depends(auth.get_current_user),
    session: AsyncSession = Depends(database.get_db)
):
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
        
    from sqlalchemy import select

    # 1. Update Earnings Ledger
    result = await session.execute(select(models.EarningsLedger))
    ledgers = result.scalars().all()
    ledger_count = 0
    for l in ledgers:
        if -10000 < l.amount < 10000:
            l.amount = int(l.amount * 100000000)
            ledger_count += 1
    
    # 2. Update Missions
    result = await session.execute(select(models.Mission))
    missions = result.scalars().all()
    mission_count = 0
    for m in missions:
        if m.reward_amount < 10000:
            m.reward_amount = int(m.reward_amount * 100000000)
            mission_count += 1
            
    # 3. Update Payouts
    result = await session.execute(select(models.Payout))
    payouts = result.scalars().all()
    payout_count = 0
    for p in payouts:
        if p.amount_cat < 10000:
            p.amount_cat = int(p.amount_cat * 100000000)
            payout_count += 1
            
    await session.commit()
    
    return {
        "message": "Migration completed",
        "migrated_ledgers": ledger_count,
        "migrated_missions": mission_count,
        "migrated_payouts": payout_count
    }

@app.on_event("startup")
async def startup():
    # Generate asset manifest
    try:
        generate_manifest()
    except Exception as e:
        print(f"Error generating manifest: {e}")

    async with async_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

        # Best-effort column patches for old DBs. Production should use apply_db_migrations.sh
        # (Alembic + run_all_migrations.py) before start; do not add new schema only here.
        from sqlalchemy import text
        try:
            # Check created_at
            res = await conn.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='missions' AND column_name='created_at'"))
            if not res.first():
                print("Running Migration: Adding created_at to missions")
                await conn.execute(text("ALTER TABLE missions ADD COLUMN created_at TIMESTAMP DEFAULT NOW()"))
            
            # Check expires_at
            res = await conn.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='missions' AND column_name='expires_at'"))
            if not res.first():
                print("Running Migration: Adding expires_at to missions")
                await conn.execute(text("ALTER TABLE missions ADD COLUMN expires_at TIMESTAMP"))

            # Check prerequisite_id
            res = await conn.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='missions' AND column_name='prerequisite_id'"))
            if not res.first():
                print("Running Migration: Adding prerequisite_id to missions")
                await conn.execute(text("ALTER TABLE missions ADD COLUMN prerequisite_id UUID REFERENCES missions(id)"))

            # AUTO-MIGRATE: admin_config columns
            admin_cols = [
                ("x_bearer_token", "VARCHAR"),
                ("x_community_username", "VARCHAR"),
                ("x_consumer_key", "VARCHAR"),
                ("x_consumer_secret", "VARCHAR"),
                ("x_access_token", "VARCHAR"),
                ("x_access_token_secret", "VARCHAR"),
                ("x_client_id", "VARCHAR"),
                ("x_client_secret", "VARCHAR"),
                ("enable_verification_release", "BOOLEAN DEFAULT TRUE"),
                ("enable_verification_debug", "BOOLEAN DEFAULT TRUE"),
                ("verification_backoff_delays", "VARCHAR DEFAULT '[120, 180, 300, 420, 600]'"),
                ("latest_version_android", "VARCHAR DEFAULT '1.0.0'"),
                ("min_version_android", "VARCHAR DEFAULT '1.0.0'"),
                ("update_url_android", "VARCHAR DEFAULT 'https://play.google.com/store/apps/details?id=org.catcoin.cat'"),
                ("latest_version_ios", "VARCHAR DEFAULT '1.0.0'"),
                ("min_version_ios", "VARCHAR DEFAULT '1.0.0'"),
                ("update_url_ios", "VARCHAR DEFAULT 'https://apps.apple.com/app/id123456789'"),
                ("latest_version_windows", "VARCHAR DEFAULT '1.0.0'"),
                ("min_version_windows", "VARCHAR DEFAULT '1.0.0'"),
                ("update_url_windows", "VARCHAR DEFAULT 'https://catcoin.in/download'"),
                ("is_runner_game_visible", "BOOLEAN DEFAULT TRUE"),
                ("is_miner_game_visible", "BOOLEAN DEFAULT TRUE"),
                ("is_tictactoe_game_visible", "BOOLEAN DEFAULT TRUE"),
                ("leaderboard_sort_by", "VARCHAR DEFAULT 'BALANCE'"),
                ("app_ads_content", "TEXT"),
                ("referral_signup_bonus_referee_amount", "FLOAT DEFAULT 100.0"),
                ("referral_signup_bonus_referrer_amount", "FLOAT DEFAULT 50.0"),
                ("referral_milestone_bonus_catoshi", "BIGINT DEFAULT 10000000"),
                ("whats_new_json", "JSONB DEFAULT '[]'::jsonb"),
                ("global_push_messages", "JSONB"),
                ("is_tile_swap_game_visible", "BOOLEAN DEFAULT TRUE"),
            ]
            
            for col_name, col_type in admin_cols:
                res = await conn.execute(text(f"SELECT column_name FROM information_schema.columns WHERE table_name='admin_config' AND column_name='{col_name}'"))
                if not res.first():
                    print(f"Running Migration: Adding {col_name} to admin_config")
                    await conn.execute(text(f"ALTER TABLE admin_config ADD COLUMN {col_name} {col_type}"))
                
            # Seed app-ads.txt if missing
            res = await conn.execute(text("SELECT app_ads_content FROM admin_config LIMIT 1"))
            row = res.first()
            if row and (not row[0]):
                seed_content = """greenadexchange.com, 12345, DIRECT, d75815a79\n\nsilverssp.com, 9675, RESELLER, 496211\n\nblueadexchange.com, XF436, DIRECT\n\norangeexchange.com, 45678, RESELLER\n\nsilverssp.com, ABE679, RESELLER\n\ngoogle.com, pub-0000000000000000, DIRECT"""
                await conn.execute(text("UPDATE admin_config SET app_ads_content = :content"), {"content": seed_content})

            seed_whats_new = Path(__file__).resolve().parent / "seed_data" / "default_whats_new.json"
            if seed_whats_new.is_file():
                try:
                    res_empty_wh = await conn.execute(
                        text(
                            """SELECT 1 FROM admin_config WHERE id = 1
                            AND COALESCE(jsonb_array_length(COALESCE(whats_new_json, '[]'::jsonb)), 0) = 0"""
                        )
                    )
                    if res_empty_wh.first():
                        blob = seed_whats_new.read_text(encoding="utf-8").strip()
                        await conn.execute(
                            text(
                                "UPDATE admin_config SET whats_new_json = CAST(:blob AS JSONB) WHERE id = 1"
                            ),
                            {"blob": blob},
                        )
                        print("Seeded admin_config.whats_new_json from seed_data/default_whats_new.json")
                except Exception as e_whns:
                    print(f"Skipping whats_new_json seed: {e_whns}")

            try:
                from services.whats_new_prune import DEFAULT_WHATS_NEW_MIN_VERSION
                from services.whats_new_prune import prune_whats_new_below

                res_pr = await conn.execute(
                    text("SELECT whats_new_json::text FROM admin_config WHERE id = 1")
                )
                row_pr = res_pr.first()
                if row_pr is not None and row_pr[0]:
                    blob_pr = str(row_pr[0]).strip()
                    if blob_pr and blob_pr != "null":
                        parsed_wh = json.loads(blob_pr)
                        trimmed_wh = prune_whats_new_below(
                            parsed_wh, DEFAULT_WHATS_NEW_MIN_VERSION
                        )
                        if len(trimmed_wh) < len(parsed_wh):
                            await conn.execute(
                                text(
                                    "UPDATE admin_config SET whats_new_json = "
                                    "CAST(:b_pr AS JSONB) WHERE id = 1"
                                ),
                                {"b_pr": json.dumps(trimmed_wh)},
                            )
                            print(
                                "Pruned admin_config.whats_new_json:",
                                len(parsed_wh),
                                "->",
                                len(trimmed_wh),
                                f"(releases below {'.'.join(str(x) for x in DEFAULT_WHATS_NEW_MIN_VERSION)} removed)",
                            )
            except Exception as e_pr_wh:
                print(f"Skipping whats_new_json prune: {e_pr_wh}")

            try:
                res_gcol = await conn.execute(
                    text(
                        "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' "
                        "AND table_name='admin_config' AND column_name='global_push_messages'"
                    )
                )
                if res_gcol.first():
                    await conn.execute(
                        text(
                            """
UPDATE admin_config
SET global_push_messages = COALESCE(global_push_messages, '{}'::jsonb)
  || jsonb_build_object(
      'en',
      to_jsonb(btrim(global_push_message)::text)
  )
WHERE global_push_message IS NOT NULL AND btrim(global_push_message) <> ''
  AND (
    global_push_messages IS NULL
    OR global_push_messages = '{}'::jsonb
    OR NOT (global_push_messages ? 'en')
)
"""
                        )
                    )
            except Exception as e_gpf:
                print(f"Skipping global_push_messages backfill: {e_gpf}")
                
            # AUTO-MIGRATE: users columns
            user_cols = [
                ("total_earnings", "FLOAT DEFAULT 0.0"),
                ("country_source", "VARCHAR(10)"),
                ("password_reset_code", "VARCHAR(6)"),
                ("password_reset_expires", "TIMESTAMP"),
                # Google Play Age Signals API v0.0.3 (Texas SB 2420 rollout) —
                # see docs/play_age_signals_integration.md.
                ("age_signal_status", "VARCHAR"),
                ("age_signal_checked_at", "TIMESTAMP"),
            ]
            for col_name, col_type in user_cols:
                res = await conn.execute(text(f"SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='{col_name}'"))
                if not res.first():
                    print(f"Running Migration: Adding {col_name} to users")
                    await conn.execute(text(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}"))

            res = await conn.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='profile_showcase_badge_ids'"))
            if not res.first():
                print("Running Migration: Adding profile_showcase_badge_ids to users")
                await conn.execute(text("ALTER TABLE users ADD COLUMN profile_showcase_badge_ids JSONB DEFAULT '[]'::jsonb"))

            res = await conn.execute(text(
                "SELECT column_name FROM information_schema.columns "
                "WHERE table_schema='public' AND table_name='refresh_tokens' AND column_name='family_id'"
            ))
            if not res.first():
                print("Running Migration: Adding family_id to refresh_tokens")
                await conn.execute(text("ALTER TABLE refresh_tokens ADD COLUMN family_id UUID"))
                await conn.execute(text("UPDATE refresh_tokens SET family_id = id WHERE family_id IS NULL"))
                await conn.execute(text("ALTER TABLE refresh_tokens ALTER COLUMN family_id SET NOT NULL"))
            else:
                await conn.execute(text("UPDATE refresh_tokens SET family_id = id WHERE family_id IS NULL"))
                await conn.execute(text("ALTER TABLE refresh_tokens ALTER COLUMN family_id SET NOT NULL"))
            await conn.execute(text("CREATE INDEX IF NOT EXISTS ix_refresh_tokens_family_id ON refresh_tokens (family_id)"))

            res = await conn.execute(
                text(
                    "SELECT column_name FROM information_schema.columns "
                    "WHERE table_schema = 'public' AND table_name = 'mining_sessions' "
                    "AND column_name = 'time_boost_slots_data'"
                )
            )
            if not res.first():
                print("Running Migration: Adding time_boost_slots_data to mining_sessions")
                await conn.execute(
                    text(
                        "ALTER TABLE mining_sessions "
                        "ADD COLUMN time_boost_slots_data VARCHAR"
                    )
                )

            # user_badges: monthly podium metadata
            badge_cols = [
                ("period_year", "INTEGER"),
                ("period_month", "INTEGER"),
                ("podium_rank", "INTEGER"),
                ("award_scope", "VARCHAR(16)"),
                ("region_code", "VARCHAR(2)"),
                ("game_type", "VARCHAR(32)"),
            ]
            res_tbl = await conn.execute(text("SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name='user_badges'"))
            if res_tbl.first():
                for col_name, col_type in badge_cols:
                    res = await conn.execute(text(f"SELECT column_name FROM information_schema.columns WHERE table_name='user_badges' AND column_name='{col_name}'"))
                    if not res.first():
                        print(f"Running Migration: Adding {col_name} to user_badges")
                        await conn.execute(text(f"ALTER TABLE user_badges ADD COLUMN {col_name} {col_type}"))
                res_ix = await conn.execute(text("SELECT indexname FROM pg_indexes WHERE indexname='uq_user_monthly_podium'"))
                if not res_ix.first():
                    print("Running Migration: Creating partial unique index uq_user_monthly_podium on user_badges")
                    await conn.execute(text(
                        """
                        CREATE UNIQUE INDEX uq_user_monthly_podium
                        ON user_badges (user_id, period_year, period_month, award_scope)
                        WHERE badge_type = 'monthly_global_podium'
                        """
                    ))
                res_ix2 = await conn.execute(text("SELECT indexname FROM pg_indexes WHERE indexname='uq_user_monthly_regional_podium'"))
                if not res_ix2.first():
                    print("Running Migration: Creating partial unique index uq_user_monthly_regional_podium")
                    await conn.execute(text(
                        """
                        CREATE UNIQUE INDEX uq_user_monthly_regional_podium
                        ON user_badges (user_id, period_year, period_month, region_code)
                        WHERE badge_type = 'monthly_regional_podium'
                        """
                    ))
                res_ix3 = await conn.execute(text("SELECT indexname FROM pg_indexes WHERE indexname='uq_user_monthly_game_podium'"))
                if not res_ix3.first():
                    print("Running Migration: Creating partial unique index uq_user_monthly_game_podium")
                    await conn.execute(text(
                        """
                        CREATE UNIQUE INDEX uq_user_monthly_game_podium
                        ON user_badges (user_id, period_year, period_month, game_type)
                        WHERE badge_type = 'monthly_game_podium'
                        """
                    ))

        except Exception as e:
            print(f"Startup Migration Error: {e}")

    # ENUM MIGRATIONS (Must run outside of a transaction block in some PG versions/configs)
    async with async_engine.connect() as conn:
        try:
            # Check GAME_REWARD enum value (rewardtype)
            res = await conn.execute(text("SELECT 1 FROM pg_enum WHERE enumlabel = 'GAME_REWARD' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'rewardtype')"))
            if not res.first():
                print("Running Migration: Adding GAME_REWARD to rewardtype enum")
                await conn.execute(text("ALTER TYPE rewardtype ADD VALUE 'GAME_REWARD'"))
                await conn.commit()
            
            # Check SPECIAL_BONUS enum value (rewardtype)
            res = await conn.execute(text("SELECT 1 FROM pg_enum WHERE enumlabel = 'SPECIAL_BONUS' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'rewardtype')"))
            if not res.first():
                print("Running Migration: Adding SPECIAL_BONUS to rewardtype enum")
                await conn.execute(text("ALTER TYPE rewardtype ADD VALUE 'SPECIAL_BONUS'"))
                await conn.commit()

            # Check GAME_BOOST enum value (rewardtype)
            res = await conn.execute(text("SELECT 1 FROM pg_enum WHERE enumlabel = 'GAME_BOOST' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'rewardtype')"))
            if not res.first():
                print("Running Migration: Adding GAME_BOOST to rewardtype enum")
                await conn.execute(text("ALTER TYPE rewardtype ADD VALUE 'GAME_BOOST'"))
                await conn.commit()

            res = await conn.execute(text("SELECT 1 FROM pg_enum WHERE enumlabel = 'REFERRAL_BONUS' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'rewardtype')"))
            if not res.first():
                print("Running Migration: Adding REFERRAL_BONUS to rewardtype enum")
                await conn.execute(text("ALTER TYPE rewardtype ADD VALUE 'REFERRAL_BONUS'"))
                await conn.commit()

            # Check GAME_BOOST enum value (sessiontype)
            res = await conn.execute(text("SELECT 1 FROM pg_enum WHERE enumlabel = 'GAME_BOOST' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'sessiontype')"))
            if not res.first():
                print("Running Migration: Adding GAME_BOOST to sessiontype enum")
                await conn.execute(text("ALTER TYPE sessiontype ADD VALUE 'GAME_BOOST'"))
                await conn.commit()
        except Exception as e:
            # If it fails (e.g. because it's already there in a way we didn't catch), we log and continue
            print(f"Enum Migration Warning/Error: {e}")
    
    # Create root user
    from database import AsyncSessionLocal
    from create_root_user import create_root_user
    async with AsyncSessionLocal() as db:
        await create_root_user(db)
        
    # Seed missions
    from seed_missions import seed_missions
    await seed_missions()
    
    # Sync user totals in background to avoid blocking health checks
    asyncio.create_task(run_sync_in_background())
    global _referral_reconciliation_task, _unverified_cleanup_task
    if settings.ENABLE_IN_PROCESS_REFERRAL_RECONCILIATION:
        _referral_reconciliation_task = asyncio.create_task(
            run_referral_reconciliation_periodically()
        )
    else:
        logging.getLogger(__name__).info(
            "In-process referral reconciliation disabled (ENABLE_IN_PROCESS_REFERRAL_RECONCILIATION=false); "
            "schedule: python -m jobs.referral_reconciliation"
        )

    if settings.ENABLE_IN_PROCESS_UNVERIFIED_USER_CLEANUP:
        _unverified_cleanup_task = asyncio.create_task(
            run_unverified_cleanup_periodically()
        )
    else:
        logging.getLogger(__name__).info(
            "In-process unverified-user cleanup disabled (ENABLE_IN_PROCESS_UNVERIFIED_USER_CLEANUP=false); "
            "schedule: python -m jobs.unverified_user_cleanup"
        )


@app.on_event("shutdown")
async def shutdown_background_tasks():
    """Stop periodic background loops cleanly on process exit."""
    global _referral_reconciliation_task, _unverified_cleanup_task
    for t in (_referral_reconciliation_task, _unverified_cleanup_task):
        if t is None:
            continue
        t.cancel()
        try:
            await t
        except asyncio.CancelledError:
            pass
    _referral_reconciliation_task = None
    _unverified_cleanup_task = None


async def run_sync_in_background():
    """Wrapper to run sync_user_totals with a fresh session in the background"""
    from database import AsyncSessionLocal
    try:
        async with AsyncSessionLocal() as db:
            await sync_user_totals(db)
    except Exception as e:
        print(f"Background Sync Error: {e}")


async def sync_user_totals(db: AsyncSession):
    """Sync User.balance and User.total_earnings from EarningsLedger"""
    from sqlalchemy import select, func, and_
    from models import User, EarningsLedger
    
    print("Startup: Syncing user balances and total earnings from ledger in background...")
    
    # 1. Update all users in a few efficient queries
    from sqlalchemy import update
    
    # Update balance
    balance_sub = (
        select(EarningsLedger.user_id, func.sum(EarningsLedger.amount).label("balance"))
        .group_by(EarningsLedger.user_id)
        .subquery()
    )
    
    # Update total_earnings
    earnings_sub = (
        select(EarningsLedger.user_id, func.sum(EarningsLedger.amount).label("total_earnings"))
        .where(EarningsLedger.amount > 0)
        .group_by(EarningsLedger.user_id)
        .subquery()
    )

    # We perform updates in a way that handles missing ledger entries correctly (set to 0)
    # This is more efficient than a loop but safe for the database
    result = await db.execute(select(User.id))
    user_ids = result.scalars().all()
    
    for i in range(0, len(user_ids), 100):
        batch = user_ids[i:i+100]
        
        # Batch update balance
        for user_id in batch:
            b_res = await db.execute(select(balance_sub.c.balance).where(balance_sub.c.user_id == user_id))
            balance = b_res.scalar() or 0.0
            
            e_res = await db.execute(select(earnings_sub.c.total_earnings).where(earnings_sub.c.user_id == user_id))
            earnings = e_res.scalar() or 0.0
            
            await db.execute(
                update(User)
                .where(User.id == user_id)
                .values(balance=balance, total_earnings=earnings)
            )
            
        await db.commit()
        print(f"Background Sync: Processed {min(i + 100, len(user_ids))}/{len(user_ids)} users")
    
    print(f"Startup Background Sync: Completed for {len(user_ids)} users.")

@app.api_route("/health", methods=["GET", "HEAD"])
async def health_check():
    """GET returns JSON; HEAD is for probes (e.g. `curl -I`) that must not assume GET-only."""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.get("/")
def read_root():
    return {"message": "Welcome to Catcoin PoE API"}

@app.get("/app-ads.txt", response_class=PlainTextResponse)
async def get_app_ads(db: AsyncSession = Depends(database.get_db)):
    from services.session_manager import SessionManager
    config = await SessionManager.get_admin_config(db)
    if config and config.app_ads_content:
        return config.app_ads_content
        
    # Fallback to physical file
    try:
        if os.path.exists("static/app-ads.txt"):
            with open("static/app-ads.txt", "r", encoding="utf-8") as f:
                return f.read()
    except Exception:
        pass
        
    return "google.com, pub-0000000000000000, DIRECT"

@app.get("/privacy-policy", response_class=HTMLResponse)
async def privacy_policy():
    with open("templates/privacy_policy.html", "r", encoding="utf-8") as f:
        return f.read()

@app.get("/delete-account", response_class=HTMLResponse)
async def delete_account_page():
    with open("templates/delete_account.html", "r", encoding="utf-8") as f:
        return f.read()

@app.get("/.well-known/assetlinks.json", include_in_schema=False)
async def get_assetlinks():
    if os.path.exists("static/.well-known/assetlinks.json"):
        with open("static/.well-known/assetlinks.json", "r") as f:
            return json.load(f)
    return []

@app.get("/.well-known/apple-app-site-association", include_in_schema=False)
async def get_apple_site_association():
    if os.path.exists("static/.well-known/apple-app-site-association"):
        with open("static/.well-known/apple-app-site-association", "r") as f:
            return json.load(f)
    return {}

@app.get("/invite", response_class=HTMLResponse, include_in_schema=False)
@app.get("/invite/", response_class=HTMLResponse, include_in_schema=False)
async def invite_no_code():
    """Graceful fallback when no referral code is provided in the invite URL."""
    return RedirectResponse(url="https://catcoin.in")

@app.get("/invite/{code}")
async def invite_redirect(
    request: Request,
    code: str,
    landing: int | None = None,
    db: AsyncSession = Depends(database.get_db),
):
    """
    One-tap invite: **302** to the correct destination from User-Agent — no OS selection.

    - Android → Google Play listing + `referrer=inv_{code}` (Play Install Referrer).
    - iPhone / iPad / iOS browsers → App Store URL from admin config.
    - Everything else → `update_url_windows` + `referral={code}` (e.g. Flutter web / download hub).

    Optional `?landing=1` serves the legacy HTML page (copy code + manual links) for support.
    """
    if not re.match(r"^[A-Za-z0-9_]+$", code):
        return RedirectResponse(url="https://catcoin.in")

    code_up = code.upper()

    from services.session_manager import SessionManager
    from services.invite_redirect import invite_destination_url

    config = await SessionManager.get_admin_config(db)
    ua = request.headers.get("user-agent", "")

    if landing == 1:
        try:
            if os.path.exists("templates/referral_landing.html"):
                with open("templates/referral_landing.html", "r", encoding="utf-8") as f:
                    content = f.read()
                play = invite_destination_url(
                    "Mozilla/5.0 (Linux; Android 14)", code_up, config
                )
                ios = invite_destination_url(
                    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", code_up, config
                )
                desktop = invite_destination_url("Mozilla/5.0 (Windows NT 10.0)", code_up, config)
                return HTMLResponse(
                    content=content.replace("__PLAY_URL__", escape(play, quote=True))
                    .replace("__IOS_URL__", escape(ios, quote=True))
                    .replace("__DESKTOP_URL__", escape(desktop, quote=True))
                    .replace("{{ code }}", escape(code_up, quote=True))
                )
        except Exception:
            pass

    url = invite_destination_url(ua, code_up, config)
    return RedirectResponse(url=url, status_code=302)

