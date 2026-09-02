from typing import List, Optional, Dict
import logging
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from datetime import datetime, timedelta
from sqlalchemy import update, func, delete, or_
import models, schemas, database, auth
import secrets
import string
from services.session_manager import SessionManager
from services.engagement_constants import ADMIN_LAST_ACTIVE_ENGAGEMENT_THRESHOLD_HOURS
from services.secret_crypto import encrypt_secret

router = APIRouter(
    prefix="/v1",
    tags=["config", "admin"],
)

@router.get("/config/", response_model=schemas.PublicAdminConfigResponse)
async def get_config(
    lang: str = Query("en", min_length=2, max_length=12),
    db: AsyncSession = Depends(database.get_db),
):
    """Public endpoint: app configuration without bot or third-party secrets."""
    from services import config_i18n

    config = await SessionManager.get_admin_config(db)
    snap = schemas.PublicAdminConfigResponse.model_validate(config)
    want = config_i18n.normalize_language_code(lang)
    msg = config_i18n.resolved_global_push_message(
        legacy_column=config.global_push_message,
        messages_by_lang=config.global_push_messages,
        lang=want,
    )
    return snap.model_copy(update={"global_push_message": msg})


@router.get("/config/whats-new", response_model=schemas.WhatsNewResponse)
async def get_whats_new(
    lang: str = Query("en", min_length=2, max_length=12),
    db: AsyncSession = Depends(database.get_db),
):
    """Public: release notes for the app's What's New UI (stored in admin_config)."""
    from services import config_i18n

    config = await SessionManager.get_admin_config(db)
    raw = getattr(config, "whats_new_json", None)
    want = config_i18n.normalize_language_code(lang)
    rows = config_i18n.whats_new_public_rows(raw, want)
    return schemas.WhatsNewResponse(
        releases=[schemas.WhatsNewReleaseItem.model_validate(r) for r in rows],
    )


@router.get("/admin/config", response_model=schemas.AdminConfigResponse)
async def get_admin_config(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """Admin-only: full configuration including bot tokens, X OAuth keys, explorer API key."""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    config = await SessionManager.get_admin_config(db)
    return schemas.AdminConfigResponse.model_validate(config)


@router.put("/admin/config", response_model=schemas.AdminConfigResponse)
async def update_config(
    config_update: schemas.AdminConfigUpdate,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin-only endpoint to update configuration"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    config = await SessionManager.get_admin_config(db)
    # Merge into current session to ensure tracking
    config = await db.merge(config)
    
    # Update fields if provided
    if config_update.ad_required_for_mining_start is not None:
        config.ad_required_for_mining_start = config_update.ad_required_for_mining_start
    if config_update.ad_required_for_speed_boost is not None:
        config.ad_required_for_speed_boost = config_update.ad_required_for_speed_boost
    if config_update.ad_required_for_time_boost is not None:
        config.ad_required_for_time_boost = config_update.ad_required_for_time_boost
    if config_update.game_ads_enabled is not None:
        config.game_ads_enabled = config_update.game_ads_enabled
    if config_update.time_boost_duration_seconds is not None:
        config.time_boost_duration_seconds = config_update.time_boost_duration_seconds
    if config_update.speed_boost_per_referral is not None:
        config.speed_boost_per_referral = config_update.speed_boost_per_referral
    if config_update.base_hashrate is not None:
        config.base_hashrate = config_update.base_hashrate
    if config_update.android_ad_unit_id is not None:
        config.android_ad_unit_id = config_update.android_ad_unit_id
    if config_update.ios_ad_unit_id is not None:
        config.ios_ad_unit_id = config_update.ios_ad_unit_id
    if config_update.base_mining_duration_minutes is not None:
        config.base_mining_duration_minutes = config_update.base_mining_duration_minutes
    if config_update.max_mining_duration_minutes is not None:
        config.max_mining_duration_minutes = config_update.max_mining_duration_minutes
    if config_update.time_extension_slots is not None:
        config.time_extension_slots = config_update.time_extension_slots
    if config_update.game_boost_config is not None:
        config.game_boost_config = config_update.game_boost_config
    if config_update.game_reward_config is not None:
        config.game_reward_config = config_update.game_reward_config
    if config_update.max_referral_boost_hashrate is not None:
        config.max_referral_boost_hashrate = config_update.max_referral_boost_hashrate
    if config_update.app_ads_content is not None:
        config.app_ads_content = config_update.app_ads_content
        
    # Bot Config Updates
    if config_update.discord_bot_token is not None:
        config.discord_bot_token = encrypt_secret(config_update.discord_bot_token)
    if config_update.discord_guild_id is not None:
        config.discord_guild_id = config_update.discord_guild_id
    if config_update.telegram_bot_token is not None:
        config.telegram_bot_token = encrypt_secret(config_update.telegram_bot_token)
    if config_update.telegram_chat_id is not None:
        config.telegram_chat_id = config_update.telegram_chat_id

    # X Config
    if config_update.x_bearer_token is not None:
        config.x_bearer_token = encrypt_secret(config_update.x_bearer_token)
    if config_update.x_community_username is not None:
        config.x_community_username = config_update.x_community_username

    # Wallet & Blockchain Config
    if config_update.global_withdrawal_enabled is not None:
        config.global_withdrawal_enabled = config_update.global_withdrawal_enabled
    if config_update.coin_explorer_api_key is not None:
        config.coin_explorer_api_key = encrypt_secret(config_update.coin_explorer_api_key)
    if config_update.enable_wallet_holding_days is not None:
        config.enable_wallet_holding_days = config_update.enable_wallet_holding_days
    if config_update.use_manual_cat_price is not None:
        config.use_manual_cat_price = config_update.use_manual_cat_price
    if config_update.manual_cat_price_usdt is not None:
        config.manual_cat_price_usdt = config_update.manual_cat_price_usdt
    if config_update.coingecko_coin_id is not None:
        config.coingecko_coin_id = config_update.coingecko_coin_id
    if config_update.catoshi_yield_percentage is not None:
        config.catoshi_yield_percentage = config_update.catoshi_yield_percentage
    if config_update.referral_boost_percentage is not None:
        config.referral_boost_percentage = config_update.referral_boost_percentage
    if config_update.max_active_referrers is not None:
        config.max_active_referrers = config_update.max_active_referrers
    if config_update.referral_signup_bonus_referee_amount is not None:
        config.referral_signup_bonus_referee_amount = (
            config_update.referral_signup_bonus_referee_amount
        )
    if config_update.referral_signup_bonus_referrer_amount is not None:
        config.referral_signup_bonus_referrer_amount = (
            config_update.referral_signup_bonus_referrer_amount
        )
    if config_update.referral_milestone_bonus_catoshi is not None:
        config.referral_milestone_bonus_catoshi = int(
            config_update.referral_milestone_bonus_catoshi
        )
    if config_update.leaderboard_sort_by is not None:
        config.leaderboard_sort_by = config_update.leaderboard_sort_by
        
    # Games UI Toggles
    if config_update.is_runner_game_visible is not None:
        config.is_runner_game_visible = config_update.is_runner_game_visible
    if config_update.is_miner_game_visible is not None:
        config.is_miner_game_visible = config_update.is_miner_game_visible
    if config_update.is_tictactoe_game_visible is not None:
        config.is_tictactoe_game_visible = config_update.is_tictactoe_game_visible
    if config_update.is_sudoku_game_visible is not None:
        config.is_sudoku_game_visible = config_update.is_sudoku_game_visible
    if config_update.is_collage_game_visible is not None:
        config.is_collage_game_visible = config_update.is_collage_game_visible
    if config_update.is_arrow_game_visible is not None:
        config.is_arrow_game_visible = config_update.is_arrow_game_visible
    if config_update.is_twenty48_game_visible is not None:
        config.is_twenty48_game_visible = config_update.is_twenty48_game_visible
    if config_update.is_tile_swap_game_visible is not None:
        config.is_tile_swap_game_visible = config_update.is_tile_swap_game_visible
    if config_update.error_report_email is not None:
        # An empty string is normalised to None by the schema validator, so
        # this path always carries a real address. Setting it back to null
        # requires submitting an explicit JSON null on the PUT body — same
        # convention as other nullable string admin_config fields.
        config.error_report_email = config_update.error_report_email

    if config_update.global_push_messages is not None:
        gm: Dict[str, str] = {}
        for k_raw, val in config_update.global_push_messages.items():
            if val is None:
                continue
            k = str(k_raw).strip().split("-")[0].split("_")[0].lower()
            text = val if isinstance(val, str) else str(val)
            if text.strip() != "":
                gm[k] = text
        config.global_push_messages = gm if gm else None
        if gm and gm.get("en"):
            config.global_push_message = gm["en"]
        elif not gm:
            config.global_push_message = None

    elif config_update.global_push_message is not None:
        if config_update.global_push_message.strip() == "":
            config.global_push_message = None
            gm2 = dict(config.global_push_messages or {})
            gm2.pop("en", None)
            config.global_push_messages = gm2 if gm2 else None
        else:
            config.global_push_message = config_update.global_push_message
            gm2 = dict(config.global_push_messages or {})
            gm2["en"] = config.global_push_message
            config.global_push_messages = gm2 if gm2 else None

    if config_update.whats_new_json is not None:
        config.whats_new_json = config_update.whats_new_json

    # Version Control Updates
    # X API Toggles
    if config_update.enable_verification_release is not None:
        config.enable_verification_release = config_update.enable_verification_release
    if config_update.enable_verification_debug is not None:
        config.enable_verification_debug = config_update.enable_verification_debug
    if config_update.verification_backoff_delays is not None:
        config.verification_backoff_delays = config_update.verification_backoff_delays
        
    # X API Keys
    if config_update.x_consumer_key is not None:
        config.x_consumer_key = encrypt_secret(config_update.x_consumer_key)
    if config_update.x_consumer_secret is not None:
        config.x_consumer_secret = encrypt_secret(config_update.x_consumer_secret)
    if config_update.x_access_token is not None:
        config.x_access_token = encrypt_secret(config_update.x_access_token)
    if config_update.x_access_token_secret is not None:
        config.x_access_token_secret = encrypt_secret(config_update.x_access_token_secret)
    if config_update.x_client_id is not None:
        config.x_client_id = encrypt_secret(config_update.x_client_id)
    if config_update.x_client_secret is not None:
        config.x_client_secret = encrypt_secret(config_update.x_client_secret)
        
    # Version Control
    # Android
    if config_update.latest_version_android is not None:
        config.latest_version_android = config_update.latest_version_android
    if config_update.min_version_android is not None:
        config.min_version_android = config_update.min_version_android
    if config_update.update_url_android is not None:
        config.update_url_android = config_update.update_url_android

    # iOS
    if config_update.latest_version_ios is not None:
        config.latest_version_ios = config_update.latest_version_ios
    if config_update.min_version_ios is not None:
        config.min_version_ios = config_update.min_version_ios
    if config_update.update_url_ios is not None:
        config.update_url_ios = config_update.update_url_ios
        
    # Windows
    if config_update.latest_version_windows is not None:
        config.latest_version_windows = config_update.latest_version_windows
    if config_update.min_version_windows is not None:
        config.min_version_windows = config_update.min_version_windows
    if config_update.update_url_windows is not None:
        config.update_url_windows = config_update.update_url_windows
    
    await db.commit()
    await db.refresh(config)
    return config

@router.get("/payouts/", response_model=list[schemas.PayoutHistoryResponse])
async def get_payout_history(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Get user's payout history"""
    user_id = user.id  # Capture before async operations
    result = await db.execute(
        select(models.Payout)
        .where(models.Payout.user_id == user_id)
        .order_by(models.Payout.created_at.desc())
    )
    payouts = result.scalars().all()
    return payouts

# --- Mission Management ---

@router.get("/admin/missions/", response_model=list[schemas.MissionResponse])
async def list_all_missions(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: List all missions (including inactive)"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    result = await db.execute(select(models.Mission).order_by(models.Mission.code))
    return result.scalars().all()

@router.post("/admin/missions/", response_model=schemas.MissionResponse)
async def create_mission(
    mission: schemas.MissionCreate,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Create a new mission"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
        
    import re
    import uuid

    # Auto-generate code if missing
    if not mission.code:
        # Slugify title: JOIN DISCORD -> JOIN_DISCORD
        slug = re.sub(r'[^a-zA-Z0-9]+', '_', mission.title).upper().strip('_')
        # Add short UUID suffix for uniqueness
        suffix = str(uuid.uuid4())[:4].upper()
        mission.code = f"{slug}_{suffix}"

    # Check existing code
    result = await db.execute(select(models.Mission).where(models.Mission.code == mission.code))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Mission code already exists")
        
    new_mission = models.Mission(**mission.model_dump())
    db.add(new_mission)
    await db.commit()
    await db.refresh(new_mission)
    return new_mission

@router.put("/admin/missions/{code}", response_model=schemas.MissionResponse)
async def update_mission(
    code: str,
    mission_update: schemas.MissionUpdate,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Update a mission"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
        
    result = await db.execute(select(models.Mission).where(models.Mission.code == code))
    db_mission = result.scalars().first()
    if not db_mission:
        raise HTTPException(status_code=404, detail="Mission not found")
        
    update_data = mission_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_mission, key, value)
        
    await db.commit()
    await db.refresh(db_mission)
    return db_mission

@router.delete("/admin/missions/{code}")
async def delete_mission(
    code: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Delete a mission"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")

    result = await db.execute(select(models.Mission).where(models.Mission.code == code))
    db_mission = result.scalars().first()
    if not db_mission:
        raise HTTPException(status_code=404, detail="Mission not found")

    # Delete dependent UserMission records first to avoid foreign key violation
    from sqlalchemy import delete, update
    await db.execute(
        delete(models.UserMission).where(models.UserMission.mission_id == db_mission.id)
    )
    
    # Unlink this mission from being a prerequisite for others
    # Set prerequisite_id = NULL where prerequisite_id == this mission.id
    await db.execute(
        update(models.Mission)
        .where(models.Mission.prerequisite_id == db_mission.id)
        .values(prerequisite_id=None)
    )
    
    await db.delete(db_mission)
    await db.commit()
    return {"message": "Mission deleted"}

# --- User Management ---

@router.get("/admin/users", response_model=schemas.AdminUserListResponse)
async def list_users(
    skip: int = 0,
    limit: int = 50,
    search: str = None,
    suspicious: bool = None,
    is_admin: bool = None,
    activity_status: str = Query(
        default="all",
        description=(
            f"Engagement filter by last_active_at (not mining): all | active | inactive; "
            f"active/inactive threshold is {ADMIN_LAST_ACTIVE_ENGAGEMENT_THRESHOLD_HOURS}h (UTC naive)"
        ),
    ),
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: List users with pagination and robust filters"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")

    skip = max(0, min(skip, 50_000))
    limit = max(1, min(limit, 200))

    from services.user_activity import (
        activity_cutoff_utc,
        admin_activity_counts,
        last_active_active_clause,
        last_active_inactive_clause,
    )

    cutoff = activity_cutoff_utc()
    activity_status = (activity_status or "all").strip().lower()
    if activity_status not in ("all", "active", "inactive"):
        raise HTTPException(status_code=400, detail="Invalid activity_status")

    # 1. Base Query
    query = select(models.User)
    count_query = select(func.count(models.User.id))

    # 2. Add Filters
    filters = []
    filters.append(
        (models.User.is_deleted == False) | (models.User.is_deleted.is_(None))  # noqa: E712
    )

    if search:
        search_filter = f"%{search}%"
        filters.append(
            (models.User.username.ilike(search_filter))
            | (models.User.email.ilike(search_filter))
        )

    if suspicious is not None:
        filters.append(models.User.is_suspicious == suspicious)

    if is_admin is not None:
        filters.append(models.User.is_admin == is_admin)

    if activity_status == "active":
        filters.append(last_active_active_clause(cutoff))
    elif activity_status == "inactive":
        filters.append(last_active_inactive_clause(cutoff))

    for f in filters:
        query = query.where(f)
        count_query = count_query.where(f)

    total_users, active_users, inactive_users = await admin_activity_counts(
        db,
        cutoff=cutoff,
        search=search,
        suspicious=suspicious,
        is_admin=is_admin,
    )

    # 3. Get Total Count
    count_result = await db.execute(count_query)
    total_count = count_result.scalar()

    # 4. Finalize User Query
    query = query.order_by(models.User.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    users = result.scalars().all()

    return schemas.AdminUserListResponse(
        users=users,
        total_count=total_count,
        has_more=(skip + limit) < total_count,
        activity_summary=schemas.AdminUserActivitySummary(
            total_users=total_users,
            active_users=active_users,
            inactive_users=inactive_users,
        ),
    )


@router.post(
    "/admin/users/ping-inactive",
    response_model=schemas.BulkPingStatsResponse,
)
async def admin_ping_inactive_users(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """
    Admin: create in-app ping rows for engagement-inactive users (last_active_at older than
    configured threshold, or null). Does not send device push notifications.

    Excludes admin accounts and soft-deleted users.
    """
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")

    from services import auth_rate_limit
    from services.ping_service import PING_KIND_ADMIN_INACTIVE, record_pings_for_recipients
    from services.user_activity import activity_cutoff_utc, last_active_inactive_clause

    await auth_rate_limit.enforce_rate_limit(
        f"ping_inactive_admin:{user.id}", max_events=1, window_seconds=300.0
    )

    cutoff = activity_cutoff_utc()
    res = await db.execute(
        select(models.User.id).where(
            (models.User.is_deleted == False) | (models.User.is_deleted.is_(None)),  # noqa: E712
            models.User.is_admin == False,  # noqa: E712
            last_active_inactive_clause(cutoff),
        )
    )
    ids = list(res.scalars().all())
    stats = await record_pings_for_recipients(
        db, recipient_ids=ids, sender_id=None, kind=PING_KIND_ADMIN_INACTIVE
    )
    return schemas.BulkPingStatsResponse(
        total_targets=stats.total_targets,
        pinged=stats.pinged,
        skipped=stats.skipped,
        failed=stats.failed,
    )

@router.get("/admin/users/{user_id}", response_model=schemas.UserResponse)
async def get_user_detail(
    user_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Get detailed info for a specific user"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    result = await db.execute(select(models.User).where(models.User.id == user_id))
    target_user = result.scalars().first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
    return target_user

@router.put("/admin/users/{user_id}", response_model=schemas.UserResponse)
async def update_user_detail(
    user_id: str,
    user_update: schemas.AdminUserUpdate,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Update a user's profile and permissions"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    result = await db.execute(select(models.User).where(models.User.id == user_id))
    target_user = result.scalars().first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Update fields if provided
    if user_update.display_name is not None:
        target_user.display_name = user_update.display_name
    if user_update.email_verified is not None:
        was_unverified = not target_user.email_verified
        target_user.email_verified = user_update.email_verified
        if user_update.email_verified:
            target_user.verification_code = None
            target_user.verification_code_expires = None
            if was_unverified:
                from services.referral_signup_bonus import grant_referral_signup_bonuses

                await grant_referral_signup_bonuses(db, target_user)
    if user_update.is_suspicious is not None:
        target_user.is_suspicious = user_update.is_suspicious
    if user_update.can_withdraw_mining is not None:
        target_user.can_withdraw_mining = user_update.can_withdraw_mining
    if user_update.can_withdraw_referrals is not None:
        target_user.can_withdraw_referrals = user_update.can_withdraw_referrals
    if user_update.can_withdraw_missions is not None:
        target_user.can_withdraw_missions = user_update.can_withdraw_missions
    if user_update.can_withdraw_games is not None:
        target_user.can_withdraw_games = user_update.can_withdraw_games
    if user_update.can_withdraw_game_boosts is not None:
        target_user.can_withdraw_game_boosts = user_update.can_withdraw_game_boosts
    if user_update.age_signal_status is not None:
        # The schema validator turns an empty string into "" — treat that as
        # "clear the field". Any other allowed string becomes the new value
        # and stamps the checked_at timestamp so we have an audit trail of
        # the override.
        new_status = user_update.age_signal_status or None
        target_user.age_signal_status = new_status
        target_user.age_signal_checked_at = datetime.utcnow() if new_status else None

    await db.commit()
    await db.refresh(target_user)
    return target_user

@router.get("/admin/users/{user_id}/stats", response_model=schemas.EnhancedStatsResponse)
async def get_user_stats(
    user_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Get earnings breakdown and stats for a specific user"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    from services.session_manager import SessionManager, EarningsManager
    from pydantic import BaseModel
    from datetime import datetime

    try:
        uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid User ID format")
    
    # Logic copied and adapted from mining.py /stats/me
    result = await db.execute(select(models.User).where(models.User.id == user_id))
    target_user = result.scalars().first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user_balance = await EarningsManager.get_user_balance(user_id, db)
    
    # Complete any expired sessions first (optional but good for accuracy)
    await SessionManager.cleanup_user_mining_sessions(user_id, db)

    # Get active sessions
    active_sessions = await SessionManager.get_active_sessions(user_id, db)
    yield_percentage = await SessionManager.calculate_combined_yield_percentage(user_id, db)
    referral_boost = await SessionManager.calculate_referral_boost_percentage(user_id, db)
    admin_cfg = await SessionManager.get_admin_config(db)

    active_session_responses = []
    for session in active_sessions:
        now = datetime.utcnow()
        elapsed_time = int((now - session.start_time).total_seconds())
        calculated_earned_catoshis = (elapsed_time * session.reward_y) // session.reward_t

        time_boost_slots = None
        if session.session_type == models.SessionType.BASE:
            time_boost_slots = await SessionManager.sync_time_boost_slots_for_session(
                session, db, admin_cfg
            )

        active_session_responses.append(schemas.ActiveSessionResponse(
            id=session.id,
            session_type=session.session_type,
            mining_for=session.mining_for,
            yield_percentage=yield_percentage / len(active_sessions) if active_sessions else yield_percentage,
            start_time=session.start_time,
            end_time=session.end_time,
            total_earned=calculated_earned_catoshis,
            reward_y=session.reward_y,
            reward_t=session.reward_t,
            time_boost_slots=time_boost_slots,
        ))
    
    breakdown_dict = await EarningsManager.calculate_earnings_breakdown(user_id, db)
    earnings_breakdown = schemas.EarningsBreakdownResponse(**breakdown_dict)
    
    verified, unverified = await EarningsManager.calculate_totals(user_id, db)
    
    return schemas.EnhancedStatsResponse(
        balance=user_balance,
        yield_percentage=yield_percentage,
        referral_boost_percentage=referral_boost,
        active_sessions=active_session_responses,
        earnings_breakdown=earnings_breakdown,
        total_verified_earnings=verified,
        total_unverified_earnings=unverified,
        available_referrals=[] # Admin doesn't need to see current user's available referral slots here
    )

@router.post("/admin/users/{user_id}/reset-missions")
async def reset_user_missions(
    user_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Reset all mission progress for a user"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
        
    # Deep Reset: Check for mission rewards in Ledger to revert balance
    # 1. Calculate total mission rewards
    query = select(models.EarningsLedger).where(
        models.EarningsLedger.user_id == user_id,
        models.EarningsLedger.reward_type == models.RewardType.MISSION_COMPLETION
    )
    result = await db.execute(query)
    ledger_entries = result.scalars().all()
    
    total_mission_rewards = sum(entry.amount for entry in ledger_entries)
    
    
    total_mission_rewards = sum(entry.amount for entry in ledger_entries)
    
    if total_mission_rewards > 0:
        # 2. Revert User Balance - NO LONGER NEEDED (Ledger is source of truth)
        # We just delete the ledger entries, and the dynamic balance updates automatically.
            
        # 3. Delete Ledger Entries
        # Getting IDs to delete
        ledger_ids = [entry.id for entry in ledger_entries]
        from sqlalchemy import delete
        
        # Note: If there are foreign keys to these ledger entries (like mappings), delete them first or cascade
        # For MISSION_COMPLETION, there are usually no session mappings, but let's be safe
        # Assuming no LedgerSessionMapping for MISSION_COMPLETION (only specific to Mining)
        
        await db.execute(
            delete(models.EarningsLedger).where(models.EarningsLedger.id.in_(ledger_ids))
        )

    # 4. Delete UserMission entries
    from sqlalchemy import delete
    await db.execute(
        delete(models.UserMission).where(models.UserMission.user_id == user_id)
    )
    
    await db.commit()
    
    return {"message": f"Missions reset for user {user_id}. Reverted {total_mission_rewards} CAT."}

@router.get("/admin/users/{user_id}/missions", response_model=list[schemas.MissionResponse])
async def list_user_missions(
    user_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: List all missions for a specific user with their status"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
        
    # Get all missions
    result = await db.execute(select(models.Mission).order_by(models.Mission.created_at.desc()))
    all_missions = result.scalars().all()
    
    # Get user progress
    result = await db.execute(select(models.UserMission).where(models.UserMission.user_id == user_id))
    user_missions = result.scalars().all()
    mission_status_map = {um.mission_id: um.status for um in user_missions}
    
    response = []
    for mission in all_missions:
        status = mission_status_map.get(mission.id)
        
        # Pydantic v2 with from_attributes=True can validate from object or dict
        # We construct a dict to inject the 'status' and 'is_completed' which come from the UserMission join
        mission_dict = {
            "id": mission.id,
            "code": mission.code,
            "title": mission.title,
            "description": mission.description,
            "link": mission.link,
            "icon": mission.icon,
            "type": mission.type,
            "reward_amount": mission.reward_amount,
            "is_active": mission.is_active,
            "expires_at": mission.expires_at,
            "prerequisite_id": mission.prerequisite_id,
            "created_at": mission.created_at,
            "status": status,
            "is_completed": status == "COMPLETED"
        }
        response.append(mission_dict)
        
    return response

@router.delete("/admin/users/{user_id}/missions/{code}")
async def reset_user_mission_specific(
    user_id: str,
    code: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Reset a specific mission for a user"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
        
    # Get Mission ID from code
    result = await db.execute(select(models.Mission).where(models.Mission.code == code))
    mission = result.scalars().first()
    if not mission:
        raise HTTPException(status_code=404, detail="Mission not found")
        
    # 1. Delete UserMission entry
    from sqlalchemy import delete
    result = await db.execute(
        delete(models.UserMission)
        .where(models.UserMission.user_id == user_id)
        .where(models.UserMission.mission_id == mission.id)
    )
    
    # 2. Revert Reward (Delete Ledger Entry)
    # Match description like "Mission reward: CODE" (from missions.py completion logic)
    # Using ILIKE for safety
    ledger_query = select(models.EarningsLedger).where(
        models.EarningsLedger.user_id == user_id,
        models.EarningsLedger.reward_type == models.RewardType.MISSION_COMPLETION,
        models.EarningsLedger.description.ilike(f"%{code}%")
    )
    ledger_result = await db.execute(ledger_query)
    ledger_entries = ledger_result.scalars().all()
    
    for entry in ledger_entries:
        await db.delete(entry)
        
    await db.commit()
    
    return {"message": f"Mission {code} reset for user {user_id}"}

@router.post("/admin/users/{user_id}/reset-mining")
async def reset_user_mining(
    user_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Stop all active mining sessions and reset booster-related state for a user."""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")

    try:
        uuid.UUID(str(user_id))
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid User ID format")

    active_session_ids = select(models.MiningSession.id).where(
        models.MiningSession.user_id == user_id,
        models.MiningSession.status == models.MiningStatus.ACTIVE,
    )
    await db.execute(
        delete(models.LedgerSessionMapping).where(
            models.LedgerSessionMapping.session_id.in_(active_session_ids)
        )
    )
    # Only return inventory boosts that were tied to an active session being torn down here.
    # Resetting all of the user's boosts (including historical, already-consumed ones) would
    # let them re-activate every past boost and double-earn the corresponding mining payout.
    await db.execute(
        update(models.UserGameBoost)
        .where(models.UserGameBoost.user_id == user_id)
        .where(models.UserGameBoost.session_id.in_(active_session_ids))
        .values(is_used=False, session_id=None)
    )
    await db.execute(
        delete(models.MiningSession).where(
            models.MiningSession.user_id == user_id,
            models.MiningSession.status == models.MiningStatus.ACTIVE,
        )
    )
    await db.execute(
        delete(models.GameCooldown).where(models.GameCooldown.user_id == user_id)
    )
    await db.commit()
    return {"message": f"Active mining and booster state reset for user {user_id}"}

@router.get("/admin/users/{user_id}/suspicious-activity", response_model=list[schemas.SuspiciousActivityResponse])
async def get_suspicious_activity(
    user_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Get suspicious activity logs for a user"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
        
    # Eager load related_user to get details
    from sqlalchemy.orm import joinedload
    query = (
        select(models.SuspiciousActivity)
        .where(models.SuspiciousActivity.user_id == user_id)
        .order_by(models.SuspiciousActivity.detected_at.desc())
        .options(joinedload(models.SuspiciousActivity.related_user))
    )
    
    result = await db.execute(query)
    activities = result.scalars().all()
    
    # Manual mapping to schema because related_user is nested object model, 
    # but schema expects flat fields related_user_username etc.
    # OR we can update schema to perform flattening?
    # Let's map it manually here for control.
    
    response = []
    for activity in activities:
        item = schemas.SuspiciousActivityResponse.model_validate(activity)
        if activity.related_user:
            item.related_user_username = activity.related_user.username
            item.related_user_email = activity.related_user.email
            item.related_user_ip = activity.related_user.ip_address
            item.related_user_device_id = activity.related_user.device_id
            item.related_user_discord_id = activity.related_user.discord_id
            item.related_user_telegram_id = activity.related_user.telegram_id
            item.related_user_x_id = activity.related_user.x_id
        response.append(item)
        
    return response

@router.post("/admin/users/{user_id}/unmark-suspicious")
async def unmark_suspicious(
    user_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """
    Admin: Clear the account-level suspicious flag only.

    This does **not** auto-resolve open fraud-review rows; resolve each
    `SuspiciousActivity` via `/admin/suspicious-activity/{id}/resolve` so
    \"safe\" always refers to a specific review item.
    """
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")

    result = await db.execute(select(models.User).where(models.User.id == user_id))
    target_user = result.scalars().first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")

    target_user.is_suspicious = False

    await db.commit()
    return {
        "message": (
            f"User {target_user.username} is no longer flagged at account level. "
            "Unresolved review items, if any, remain in the fraud log until individually resolved."
        )
    }

@router.post("/admin/users/{user_id}/activate-email")
async def admin_activate_user_email(
    user_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """
    Admin: manually mark a user's email as verified.

    Use when a user can't receive their verification code (typo'd email,
    blocked by the provider, etc.). Mirrors the side effects of
    ``POST /verify-email`` minus the code check: clears any pending
    verification/reset codes and grants referral signup bonuses if the
    user was invited. Idempotent — already-verified users return 200
    without re-running side effects.
    """
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")

    try:
        uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid User ID format")

    from services import auth_rate_limit
    # 30 manual activations per hour per admin is generous for support work
    # but stops a stuck script from sweeping every unverified row.
    await auth_rate_limit.enforce_rate_limit(
        f"activate_email_admin:{user.id}", max_events=30, window_seconds=3600.0
    )

    result = await db.execute(select(models.User).where(models.User.id == user_id))
    target_user = result.scalars().first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")

    if target_user.email_verified:
        return {
            "message": "User email is already verified.",
            "user_id": str(target_user.id),
            "email_verified": True,
            "already_verified": True,
        }

    from services.referral_signup_bonus import grant_referral_signup_bonuses

    target_user.email_verified = True
    target_user.verification_code = None
    target_user.verification_code_expires = None
    target_user.password_reset_code = None
    target_user.password_reset_expires = None

    # grant_referral_signup_bonuses checks email_verified first, so it must
    # be flipped above before this call. The function is idempotent against
    # the EarningsLedger so re-running on a previously-verified user is safe.
    await grant_referral_signup_bonuses(db, target_user)

    target_username = target_user.username
    target_email = target_user.email

    await db.commit()

    logging.info(
        "Admin %s manually activated email for user %s (id=%s, email=%s)",
        user.id, target_username, user_id, target_email,
    )

    return {
        "message": f"Email verified for {target_username}.",
        "user_id": str(user_id),
        "email_verified": True,
        "already_verified": False,
    }


@router.post("/admin/suspicious-activity/{activity_id}/resolve")
async def resolve_suspicious_activity(
    activity_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Mark one `SuspiciousActivity` row reviewed (resolved); clears account flag only if no other open rows."""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
        
    result = await db.execute(select(models.SuspiciousActivity).where(models.SuspiciousActivity.id == activity_id))
    activity = result.scalars().first()
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")
        
    activity.is_resolved = True
    await db.commit()
    
    # Check if user has any other unresolved suspicious activities
    remaining = await db.execute(
        select(models.SuspiciousActivity)
        .where(
            models.SuspiciousActivity.user_id == activity.user_id,
            models.SuspiciousActivity.is_resolved == False
        )
        .limit(1)
    )
    
    if not remaining.scalars().first():
        user_result = await db.execute(select(models.User).where(models.User.id == activity.user_id))
        target_user = user_result.scalars().first()
        if target_user:
            target_user.is_suspicious = False
            await db.commit()
            
    return {"message": "Review item resolved (this event only)."}

@router.post("/admin/x/post")
async def post_x_update(
    post: schemas.XPostRequest,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Post update to X (Twitter)"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")

    from services import auth_rate_limit
    from services.x_service import XService
    from datetime import datetime, timedelta

    # 12 tweets / hour / admin is more than any human campaign needs and stops
    # a stuck script from burning through the X API quota.
    await auth_rate_limit.enforce_rate_limit(
        f"x_post_admin:{user.id}", max_events=12, window_seconds=3600.0
    )

    # 1. Post to X (external side effect — cannot be rolled back).
    try:
        result = await XService.post_tweet(post.text, db)
    except Exception:
        logging.exception("Admin X post failed before tweet was sent")
        raise HTTPException(
            status_code=502,
            detail="Failed to post to X",
        )

    tweet_id = (result or {}).get("data", {}).get("id")
    if not tweet_id:
        # Tweet API responded but didn't return an id; nothing to link a mission to.
        return {
            "message": "Tweet posted but no id returned; mission not created.",
            "id": None,
            "mission_code": None,
            "data": result,
            "mission_created": False,
        }

    # 2. Create the engagement mission. If this fails, surface partial success
    #    so the admin doesn't retry and double-post the tweet.
    mission_code = f"X_POST_{tweet_id}"
    try:
        prereq_result = await db.execute(
            select(models.Mission).where(models.Mission.code == "FOLLOW_X")
        )
        prereq_mission = prereq_result.scalars().first()

        expires_at = datetime.utcnow() + timedelta(days=post.expires_in_days)
        new_mission = models.Mission(
            code=mission_code,
            title=f"Engage: {post.text[:20]}...",
            description=f"Like & Repost this update from Catcoin: \"{post.text}\"",
            link=f"https://twitter.com/i/web/status/{tweet_id}",
            icon="twitter",
            type=models.MissionType.SOCIAL,
            reward_amount=post.reward_amount,
            is_active=True,
            created_at=datetime.utcnow(),
            expires_at=expires_at,
            prerequisite_id=prereq_mission.id if prereq_mission else None,
        )
        db.add(new_mission)
        await db.commit()
    except Exception:
        await db.rollback()
        logging.exception(
            "Admin X post: tweet %s posted but mission insert failed", tweet_id
        )
        return {
            "message": (
                "Tweet posted, but mission creation failed. "
                "Do not retry; create the mission manually."
            ),
            "id": tweet_id,
            "mission_code": None,
            "data": result,
            "mission_created": False,
        }

    return {
        "message": "Tweet posted and mission created successfully",
        "id": tweet_id,
        "mission_code": mission_code,
        "data": result,
        "mission_created": True,
    }

@router.post("/admin/bonus/generate", response_model=list[schemas.SpecialBonusResponse])
async def generate_special_bonuses(
    request: schemas.SpecialBonusGenerateRequest,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Admin: Generate unique 24-character alpha-numeric codes"""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")

    from services import auth_rate_limit
    # Per-admin batch cap; each call may insert up to 500 rows with N+1 lookups.
    await auth_rate_limit.enforce_rate_limit(
        f"bonus_generate_admin:{user.id}", max_events=6, window_seconds=3600.0
    )

    alphabet = string.ascii_uppercase + string.digits
    generated_codes = []
    
    for _ in range(request.count):
        # Generate 24-char unique code
        while True:
            code = ''.join(secrets.choice(alphabet) for _ in range(24))
            # Check uniqueness
            result = await db.execute(select(models.SpecialBonusCode).where(models.SpecialBonusCode.code == code))
            if not result.scalars().first():
                break
        
        bonus = models.SpecialBonusCode(
            code=code,
            amount=request.amount,
            is_used=False
        )
        db.add(bonus)
        generated_codes.append(bonus)
    
    await db.commit()
    for bonus in generated_codes:
        await db.refresh(bonus)
        
    return generated_codes


@router.post("/admin/leaderboard/award-monthly-podium", response_model=schemas.AwardMonthlyPodiumResponse)
async def award_monthly_podium(
    request: schemas.AwardMonthlyPodiumRequest,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """Admin: grant monthly podium UserBadges (global, all regional countries, all games)."""
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")

    from services import auth_rate_limit
    # Re-running this for the same month is idempotent but expensive; cap to a
    # handful of calls per hour per admin.
    await auth_rate_limit.enforce_rate_limit(
        f"podium_award_admin:{user.id}", max_events=4, window_seconds=3600.0
    )

    from services.monthly_podium_awards import award_all_monthly_podiums

    stats = await award_all_monthly_podiums(db, year=request.year, month=request.month)
    y, m = stats["period_year"], stats["period_month"]
    msg = (
        f"{y}-{m:02d}: global +{len(stats['global_awarded'])}/skip {len(stats['global_skipped'])}; "
        f"regional +{stats['regional_awarded_count']}/skip {stats['regional_skipped_count']}; "
        f"games +{stats['game_awarded_count']}/skip {stats['game_skipped_count']}."
    )
    return schemas.AwardMonthlyPodiumResponse(
        period_year=y,
        period_month=m,
        awarded=stats["global_awarded"],
        skipped_existing=stats["global_skipped"],
        regional_awarded_count=stats["regional_awarded_count"],
        regional_skipped_count=stats["regional_skipped_count"],
        game_awarded_count=stats["game_awarded_count"],
        game_skipped_count=stats["game_skipped_count"],
        message=msg,
    )

