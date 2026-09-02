from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import models, schemas, database, auth
from services.mining import MiningService
from services.session_manager import SessionManager, EarningsManager
from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime
from sqlalchemy import desc, func, or_

router = APIRouter(
    tags=["mining"],
)

async def verify_ad(user_id: UUID, db: AsyncSession, purpose: str):
    # purpose: 'mining_start' or 'time_boost'
    stmt = select(models.AdminConfig).limit(1)
    res = await db.execute(stmt)
    config = res.scalars().first()
    
    if not config:
        return

    required = False
    if purpose == 'mining_start':
        required = config.ad_required_for_mining_start
    elif purpose == 'time_boost':
        required = config.ad_required_for_time_boost
        
    if required:
        stmt = select(models.AdView).where(
            models.AdView.user_id == user_id,
            models.AdView.verified == True,
            models.AdView.used_at == None
        ).order_by(models.AdView.timestamp.asc()).limit(1)
        res = await db.execute(stmt)
        ad_view = res.scalars().first()
        
        if not ad_view:
            # Bypass for testing if debug mode is enabled
            if config.enable_verification_debug:
                print(f"Debug Mode: Bypassing Ad Verification for user {user_id}")
                return
            
            raise HTTPException(status_code=400, detail="Ad verification failed: No verified ad view found")
        
        ad_view.used_at = datetime.utcnow()
        # db.add(ad_view) # Already tracked by session

@router.post("/mining/start", response_model=schemas.MiningSessionResponse)
async def start_mining(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    try:
        user_id = user.id  # Capture before async operations
        await verify_ad(user_id, db, 'mining_start')
        session = await SessionManager.create_base_session(user_id, db)
        return session
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/mining/boost/{referral_id}", response_model=schemas.MiningSessionResponse)
async def boost_referral(
    referral_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    try:
        user_id = user.id  # Capture before async operations
        user_referral_code = user.referral_code
        session = await SessionManager.create_referral_boost_session(user_id, user_referral_code, referral_id, db)
        return session
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/stats/me", response_model=schemas.EnhancedStatsResponse)
async def get_enhanced_stats(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    from datetime import datetime, timedelta

    # Eagerly load the user object and store ID to prevent MissingGreenlet error
    result = await db.execute(
        select(models.User).where(models.User.id == user.id)
    )
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Store user attributes upfront to avoid lazy loading issues (MissingGreenlet)
    user_id = user.id
    user_username = user.username
    user_referral_code = user.referral_code
    # user_balance = user.balance <-- DEPRECATED: Use Ledger Calculation
    user_balance = await EarningsManager.get_user_balance(user_id, db)

    # Complete expired sessions and referral boosts tied to inactive referrals
    completed_sessions = await SessionManager.cleanup_user_mining_sessions(user_id, db)
    if completed_sessions:
        print(f"Auto-completed {len(completed_sessions)} mining sessions for user {user_username}")

    # Get active sessions
    active_sessions = await SessionManager.get_active_sessions(user_id, db)
    yield_percentage = await SessionManager.calculate_combined_yield_percentage(user_id, db)
    referral_boost = await SessionManager.calculate_referral_boost_percentage(user_id, db)
    
    # Build active session responses with real-time earnings
    active_session_responses = []
    config = await SessionManager.get_admin_config(db)
    
    for session in active_sessions:
        # Calculate y / t integer catoshis based on time elapsed
        now = datetime.utcnow()
        elapsed_time = int((now - session.start_time).total_seconds())
        
        # Calculate session-specific yield percentage
        if session.session_type == models.SessionType.BASE:
            session_yield = SessionManager.admin_catoshi_yield_pct(config)
        elif session.session_type == models.SessionType.REFERRAL_BOOST:
            session_yield = SessionManager.admin_referral_boost_pct(config)
        elif session.session_type == models.SessionType.GAME_BOOST:
            # Find the linked boost to get its specific percentage
            boost_res = await db.execute(
                select(models.UserGameBoost.percentage)
                .where(models.UserGameBoost.session_id == session.id)
            )
            session_yield = boost_res.scalar() or 0.0
        else:
            session_yield = 0.0
            
        calculated_earned_catoshis = (elapsed_time * session.reward_y) // session.reward_t

        time_boost_slots = None
        if session.session_type == models.SessionType.BASE:
            time_boost_slots = await SessionManager.sync_time_boost_slots_for_session(
                session, db, config
            )

        active_session_responses.append(schemas.ActiveSessionResponse(
            id=session.id,
            session_type=session.session_type,
            mining_for=session.mining_for,
            yield_percentage=session_yield,
            start_time=session.start_time,
            end_time=session.end_time,
            total_earned=calculated_earned_catoshis,
            reward_y=session.reward_y,
            reward_t=session.reward_t,
            time_boost_slots=time_boost_slots,
        ))
    
    # Get earnings breakdown
    breakdown_dict = await EarningsManager.calculate_earnings_breakdown(user_id, db)
    earnings_breakdown = schemas.EarningsBreakdownResponse(**breakdown_dict)
    
    # Get totals
    verified, unverified = await EarningsManager.calculate_totals(user_id, db)
    
    # Get available referrals
    available_referrals = await SessionManager.get_available_referrals(user_id, user_referral_code, db)
    
    return schemas.EnhancedStatsResponse(
        balance=user_balance,
        yield_percentage=yield_percentage,
        referral_boost_percentage=referral_boost,
        active_sessions=active_session_responses,
        earnings_breakdown=earnings_breakdown,
        total_verified_earnings=verified,
        total_unverified_earnings=unverified,
        available_referrals=available_referrals
    )

@router.post("/complete-sessions")
async def manual_complete_sessions(
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Manually trigger completion of expired sessions"""
    completed = await SessionManager.cleanup_user_mining_sessions(current_user.id, db)
    return {"message": f"Completed {len(completed)} sessions"}

class ExtensionRequest(BaseModel):
    hours: int = Field(ge=1, le=168)

@router.post("/mining/extend")
async def extend_mining_session(
    request: ExtensionRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Extend active mining session"""
    user_id = current_user.id  # Capture before async operations
    await verify_ad(user_id, db, 'time_boost')
    session = await SessionManager.extend_session(user_id, request.hours, db)
    return {
        "message": "Session extended successfully",
        "new_end_time": session.end_time,
        "total_duration_hours": (session.end_time - session.start_time).total_seconds() / 3600
    }

@router.get("/mining/available-game-boosts", response_model=List[schemas.UserGameBoostResponse])
async def get_available_game_boosts(
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """List unactivated game boosts for the current user"""
    result = await db.execute(
        select(models.UserGameBoost)
        .where(models.UserGameBoost.user_id == current_user.id)
        .where(models.UserGameBoost.is_used == False)
        .order_by(models.UserGameBoost.earned_at.desc())
    )
    return result.scalars().all()

@router.post("/mining/activate-game-boost", response_model=schemas.MiningSessionResponse)
async def activate_game_boost(
    request: schemas.ActivateBoostRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Activate a game boost and start a mining boost session"""
    session = await SessionManager.create_game_boost_session(current_user.id, request.boost_id, db)
    return session

@router.post("/mining/bonus/redeem")
async def redeem_special_bonus(
    request: schemas.SpecialBonusRedeemRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Redeem a unique 24-character special bonus code"""
    # 1. Find the code
    result = await db.execute(
        select(models.SpecialBonusCode)
        .where(models.SpecialBonusCode.code == request.code)
    )
    bonus = result.scalars().first()
    
    if not bonus:
        raise HTTPException(status_code=404, detail="Invalid bonus code")
    
    if bonus.is_used:
        raise HTTPException(status_code=400, detail="Bonus code already redeemed")
    
    # 2. Mark as used
    bonus.is_used = True
    bonus.used_by = current_user.id
    bonus.used_at = datetime.utcnow()
    
    # 3. Add reward to user balance via EarningsManager
    description = f"Special Bonus Code Redemption: {request.code}"
    await EarningsManager.create_reward_entry(
        user_id=current_user.id,
        amount=bonus.amount,
        reward_type=models.RewardType.SPECIAL_BONUS,
        description=description,
        db=db
    )
    
    await db.commit()
    
    return {
        "message": "Bonus redeemed successfully!",
        "amount": bonus.amount
    }


@router.post("/referrals/ping-all", response_model=schemas.BulkPingStatsResponse)
async def ping_all_referrals(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """
    Create **in-app** ping rows for **engagement-inactive** users referred by the
    authenticated account (`last_active_at` null or older than the shared admin
    engagement threshold — same rule as admin inactive ping; not mining state).

    Does not send device push notifications — only persists `user_ping_notifications`
    for downstream UX or a future notifier.

    Targets only non-deleted users whose `referred_by` matches the caller's
    `referral_code` (case-insensitive), excluding self; never other referrers' trees.
    """
    from services import auth_rate_limit
    from services.ping_service import PING_KIND_REFERRAL_BULK, record_pings_for_recipients
    from services.user_activity import activity_cutoff_utc, last_active_inactive_clause

    await auth_rate_limit.enforce_rate_limit(
        f"ping_referrals:{user.id}", max_events=1, window_seconds=3600.0
    )

    code = (user.referral_code or "").strip()
    if not code:
        raise HTTPException(status_code=400, detail="Referral code missing")

    cutoff = activity_cutoff_utc()
    res = await db.execute(
        select(models.User.id).where(
            func.lower(models.User.referred_by) == func.lower(code),
            models.User.id != user.id,
            (models.User.is_deleted == False) | (models.User.is_deleted.is_(None)),  # noqa: E712
            last_active_inactive_clause(cutoff),
        )
    )
    ids = list(res.scalars().all())
    stats = await record_pings_for_recipients(
        db, recipient_ids=ids, sender_id=user.id, kind=PING_KIND_REFERRAL_BULK
    )
    return schemas.BulkPingStatsResponse(
        total_targets=stats.total_targets,
        pinged=stats.pinged,
        skipped=stats.skipped,
        failed=stats.failed,
    )
