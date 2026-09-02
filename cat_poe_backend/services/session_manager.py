import uuid
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import aliased
from sqlalchemy import and_, func
from typing import List, Dict, Optional
import math
import models, schemas
from admin_config_defaults import (
    DEFAULT_GAME_BOOST_CONFIG_JSON,
    DEFAULT_GAME_REWARD_CONFIG_JSON,
)
from services.price_service import price_service
from services import time_boost_state as tbs

class SessionManager:
    """Manages multi-session mining architecture"""

    @staticmethod
    def admin_catoshi_yield_pct(config: models.AdminConfig) -> float:
        """Legacy rows may have NULL; matches Column default 100.0."""
        v = config.catoshi_yield_percentage
        return float(v) if v is not None else 100.0

    @staticmethod
    def admin_referral_boost_pct(config: models.AdminConfig) -> float:
        """Legacy rows may have NULL; matches Column default 10.0."""
        v = config.referral_boost_percentage
        return float(v) if v is not None else 10.0

    @staticmethod
    def admin_max_active_referrers(config: models.AdminConfig) -> int:
        v = config.max_active_referrers
        return int(v) if v is not None else 10

    @staticmethod
    async def get_admin_config(db: AsyncSession) -> models.AdminConfig:
        """Get or create singleton AdminConfig"""
        result = await db.execute(select(models.AdminConfig).where(models.AdminConfig.id == 1))
        config = result.scalars().first()
        if not config:
            try:
                config = models.AdminConfig(
                    id=1,
                    game_boost_config=DEFAULT_GAME_BOOST_CONFIG_JSON,
                    game_reward_config=DEFAULT_GAME_REWARD_CONFIG_JSON,
                )
                db.add(config)
                await db.commit()
                await db.refresh(config)
            except Exception: # Handle race condition (IntegrityError)
                await db.rollback()
                result = await db.execute(select(models.AdminConfig).where(models.AdminConfig.id == 1))
                config = result.scalars().first()
        return config

    @staticmethod
    def compute_rate(p_usd: float, r_usd: float = 0.05) -> tuple[int, int]:
        """Calculates exact integer Catoshi rate (Y catoshi / T seconds) based on USD."""
        s = 100_000_000
        d = 86400
        
        if p_usd <= 0:
            return (0, 1)
            
        # Total catoshi per day = (r_usd / p_usd) * 100_000_000
        catoshi_day = int((r_usd / p_usd) * s)
        if catoshi_day <= 0:
            return (0, 1)
            
        # Step 2: reduce fraction
        g = math.gcd(catoshi_day, d)
        y = catoshi_day // g
        t = d // g
        
        return (y, t)

    @staticmethod
    def _time_boost_slots_to_response(state: Dict, now: datetime) -> List[schemas.TimeBoostSlotResponse]:
        inactive = set(state.get("inactive_hours") or [])
        out: List[schemas.TimeBoostSlotResponse] = []
        for h in state.get("slots") or []:
            cd_iso = (state.get("cooldowns") or {}).get(str(h))
            cd_until = None
            if cd_iso:
                try:
                    parsed = tbs.parse_iso_utc_naive(cd_iso)
                    if parsed > now:
                        cd_until = parsed
                except (ValueError, TypeError):
                    cd_until = None
            out.append(
                schemas.TimeBoostSlotResponse(
                    hours=h,
                    cooldown_until=cd_until,
                    active=(h not in inactive),
                )
            )
        return out

    @staticmethod
    async def sync_time_boost_slots_for_session(
        session: models.MiningSession,
        db: AsyncSession,
        config: models.AdminConfig,
    ) -> List[schemas.TimeBoostSlotResponse]:
        """Initialize (if needed), reconcile, persist JSON, return slots for API."""
        if session.session_type != models.SessionType.BASE:
            return []
        now = datetime.utcnow()
        ext_mins = tbs.extension_minutes_from_config(config.time_extension_slots)
        state = tbs.load_state(session.time_boost_slots_data)
        if not state or not state.get("slots"):
            state = tbs.new_random_slots_state(ext_mins)
        max_duration = config.max_mining_duration_minutes or 1440
        current_duration = int((session.end_time - session.start_time).total_seconds() / 60)
        remaining = max(0, max_duration - current_duration)
        state = tbs.reconcile_time_boost_state(state, remaining, ext_mins, now)
        new_json = tbs.dump_state(state)
        if session.time_boost_slots_data != new_json:
            session.time_boost_slots_data = new_json
            await db.commit()
        return SessionManager._time_boost_slots_to_response(state, now)
    
    @staticmethod
    async def get_active_sessions(user_id: str, db: AsyncSession) -> List[models.MiningSession]:
        """Get all active sessions for a user.

        Ordered with BASE first (then REFERRAL_BOOST etc.) so that clients
        which still naively pick ``activeSessions.first`` don't accidentally
        treat a shorter boost session as the primary one — which was firing
        a "Mining Stopped!" push too early. Within a session type, ties are
        broken by the latest end_time so the "primary" really is the one
        most likely to run longest.
        """
        result = await db.execute(
            select(models.MiningSession)
            .where(models.MiningSession.user_id == user_id)
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time > datetime.utcnow())
            .order_by(
                # BASE sorts before REFERRAL_BOOST alphabetically; this is
                # incidental but correct for both current enum values.
                # If a new session type is added that should also sort
                # ahead of REFERRAL_BOOST, replace with an explicit CASE.
                models.MiningSession.session_type.asc(),
                models.MiningSession.end_time.desc(),
            )
        )
        return result.scalars().all()

    @staticmethod
    async def referral_user_has_active_base_mining(
        referral_user_id, db: AsyncSession
    ) -> bool:
        """True if the referred user currently has an active BASE mining session."""
        now = datetime.utcnow()
        res = await db.execute(
            select(models.MiningSession.id)
            .where(models.MiningSession.user_id == referral_user_id)
            .where(models.MiningSession.session_type == models.SessionType.BASE)
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time > now)
            .limit(1)
        )
        return res.scalar() is not None

    @staticmethod
    async def get_available_referrals(user_id: str, referral_code: str, db: AsyncSession) -> List[schemas.ReferralInfo]:
        """Get list of referrals with boost info"""
        result = await db.execute(
            select(models.User)
            .where(models.User.referred_by == referral_code)
        )
        referrals = result.scalars().all()
        
        referral_infos = []
        for referral in referrals:
            is_active = await SessionManager.referral_user_has_active_base_mining(
                referral.id, db
            )
            
            # Check if already boosting
            result = await db.execute(
                select(models.MiningSession.id)
                .where(models.MiningSession.user_id == user_id)
                .where(models.MiningSession.session_type == models.SessionType.REFERRAL_BOOST)
                .where(models.MiningSession.mining_for == referral.id)
                .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
                .where(models.MiningSession.end_time > datetime.utcnow())
            )
            boost_session = result.scalars().first()
            
            can_boost = is_active and not boost_session
            
            referral_infos.append(schemas.ReferralInfo(
                referral_id=referral.id,
                referral_username=referral.username,
                referral_display_name=referral.display_name or referral.username,
                is_active=is_active,
                last_active_at=referral.last_active_at,
                can_boost=can_boost,
                active_boost_session_id=boost_session
            ))
        
        return referral_infos
    
    @staticmethod
    async def calculate_combined_yield_percentage(user_id: str, db: AsyncSession) -> float:
        """Calculate total yield percentage from base + referral + game boosts"""
        config = await SessionManager.get_admin_config(db)
        base_yield = SessionManager.admin_catoshi_yield_pct(config)

        # Calculate boost categories
        referral_boost = await SessionManager.calculate_referral_boost_percentage(user_id, db)
        game_boost = await SessionManager.calculate_game_boost_percentage(user_id, db)
        
        return base_yield + referral_boost + game_boost
    
    @staticmethod
    async def calculate_referral_boost_percentage(user_id: str, db: AsyncSession) -> float:
        """Referral boost % only counts boosts where the referred user has an active BASE mining session."""
        config = await SessionManager.get_admin_config(db)
        now = datetime.utcnow()
        RefBase = aliased(models.MiningSession)

        result = await db.execute(
            select(func.count(models.MiningSession.id))
            .join(models.User, models.MiningSession.mining_for == models.User.id)
            .join(
                RefBase,
                and_(
                    RefBase.user_id == models.User.id,
                    RefBase.session_type == models.SessionType.BASE,
                    RefBase.status == models.MiningStatus.ACTIVE,
                    RefBase.end_time > now,
                ),
            )
            .where(models.MiningSession.user_id == user_id)
            .where(models.MiningSession.session_type == models.SessionType.REFERRAL_BOOST)
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time > now)
        )
        active_boost_count = result.scalar() or 0

        ref_pct = SessionManager.admin_referral_boost_pct(config)
        max_ref = SessionManager.admin_max_active_referrers(config)
        raw_boost = active_boost_count * ref_pct
        max_boost = max_ref * ref_pct
        return min(raw_boost, max_boost)
    
    @staticmethod
    async def calculate_game_boost_percentage(user_id: str, db: AsyncSession) -> float:
        """Calculate total percentage from all active game boost sessions"""
        # Sum percentages from linked UserGameBoosts
        result = await db.execute(
            select(func.sum(models.UserGameBoost.percentage))
            .join(models.MiningSession, models.UserGameBoost.session_id == models.MiningSession.id)
            .where(models.MiningSession.user_id == user_id)
            .where(models.MiningSession.session_type == models.SessionType.GAME_BOOST)
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time > datetime.utcnow())
        )
        return float(result.scalar() or 0.0)
    
    @staticmethod
    async def extend_session(user_id: str, extension_hours: int, db: AsyncSession) -> models.MiningSession:
        """Extend an active base mining session"""
        from fastapi import HTTPException
        
        # Get active base session
        result = await db.execute(
            select(models.MiningSession)
            .where(models.MiningSession.user_id == user_id)
            .where(models.MiningSession.session_type == models.SessionType.BASE)
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time > datetime.utcnow())
        )
        session = result.scalars().first()
        
        if not session:
            raise HTTPException(status_code=400, detail="No active base mining session found")
            
        config = await SessionManager.get_admin_config(db)
        ext_mins = tbs.extension_minutes_from_config(config.time_extension_slots)
        extension_minutes = extension_hours * 60
        if extension_minutes not in ext_mins:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid extension duration. Available slots (min): {ext_mins}",
            )

        await SessionManager.sync_time_boost_slots_for_session(session, db, config)
        now = datetime.utcnow()
        state = tbs.load_state(session.time_boost_slots_data)
        if not state or not state.get("slots"):
            state = tbs.new_random_slots_state(ext_mins)
            session.time_boost_slots_data = tbs.dump_state(state)
            await db.commit()

        max_duration = config.max_mining_duration_minutes or 1440
        current_duration_minutes = int((session.end_time - session.start_time).total_seconds() / 60)
        remaining_capacity_minutes = max_duration - current_duration_minutes

        if extension_hours not in state.get("slots", []):
            raise HTTPException(
                status_code=400,
                detail="This time boost is not assigned to your current mining session.",
            )
        if extension_hours in (state.get("inactive_hours") or []):
            raise HTTPException(
                status_code=400,
                detail="This time boost is inactive for your remaining session time.",
            )
        cd_iso = (state.get("cooldowns") or {}).get(str(extension_hours))
        if cd_iso:
            try:
                if tbs.parse_iso_utc_naive(cd_iso) > now:
                    raise HTTPException(status_code=400, detail="This time boost is still on cooldown.")
            except HTTPException:
                raise
            except (ValueError, TypeError):
                pass

        requested_extension_minutes = extension_minutes
        
        if remaining_capacity_minutes <= 0:
            raise HTTPException(
                status_code=400,
                detail=f"Session is already at the maximum duration of {max_duration // 60} hours."
            )
        
        # Cap the extension to whatever capacity remains (discard overflow silently)
        actual_extension_minutes = min(requested_extension_minutes, remaining_capacity_minutes)
        
        # Extend session by the capped amount
        session.end_time = session.end_time + timedelta(minutes=actual_extension_minutes)

        state = tbs.load_state(session.time_boost_slots_data) or state
        state.setdefault("cooldowns", {})
        state["cooldowns"][str(extension_hours)] = (
            now + timedelta(hours=extension_hours)
        ).isoformat()
        new_duration_minutes = int((session.end_time - session.start_time).total_seconds() / 60)
        remaining_after = max(0, max_duration - new_duration_minutes)
        state = tbs.reconcile_time_boost_state(state, remaining_after, ext_mins, now)
        session.time_boost_slots_data = tbs.dump_state(state)
        
        # Sync active boost sessions
        result = await db.execute(
            select(models.MiningSession)
            .where(models.MiningSession.user_id == user_id)
            .where(models.MiningSession.session_type == models.SessionType.REFERRAL_BOOST)
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time > datetime.utcnow())
        )
        boost_sessions = result.scalars().all()
        for boost_session in boost_sessions:
            boost_session.end_time = session.end_time
            
        # Update user activity since they engaged with mining
        user_res = await db.execute(select(models.User).where(models.User.id == user_id))
        user = user_res.scalars().first()
        if user:
            user.last_active_at = datetime.utcnow()
            
        await db.commit()
        await db.refresh(session)
        
        return session
    
    @staticmethod
    async def create_base_session(user_id: str, db: AsyncSession) -> models.MiningSession:
        """Start a new base mining session"""
        from fastapi import HTTPException
        
        # Check for existing active base session
        result = await db.execute(
            select(models.MiningSession)
            .where(models.MiningSession.user_id == user_id)
            .where(models.MiningSession.session_type == models.SessionType.BASE)
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time > datetime.utcnow())
        )
        existing_session = result.scalars().first()
        
        if existing_session:
            raise HTTPException(status_code=400, detail="Active base mining session already exists")
            
        config = await SessionManager.get_admin_config(db)
        duration_minutes = config.base_mining_duration_minutes or 480 # Default 8 hours
        
        p_usd = await price_service.get_cat_price_usd(db)
        # Daily target yield in USD
        r_usd_base = 0.05 * (SessionManager.admin_catoshi_yield_pct(config) / 100.0)
        y, t = SessionManager.compute_rate(p_usd, r_usd_base)
        
        now = datetime.utcnow()
        ext_mins = tbs.extension_minutes_from_config(config.time_extension_slots)
        session = models.MiningSession(
            user_id=user_id,
            session_type=models.SessionType.BASE,
            start_time=now,
            end_time=now + timedelta(minutes=duration_minutes),
            status=models.MiningStatus.ACTIVE,
            reward_y=y,
            reward_t=t,
            total_earned=0,
            time_boost_slots_data=tbs.dump_state(tbs.new_random_slots_state(ext_mins)),
        )
        
        db.add(session)
        
        # Update user activity since they started mining
        user_res = await db.execute(select(models.User).where(models.User.id == user_id))
        user = user_res.scalars().first()
        if user:
            user.last_active_at = datetime.utcnow()
            
        await db.commit()
        await db.refresh(session)
        
        return session

    @staticmethod
    async def create_referral_boost_session(user_id: str, user_referral_code: str, referral_id: str, db: AsyncSession) -> models.MiningSession:
        """
        Create a separate REFERRAL_BOOST MiningSession (synced to the base session end_time).
        Runs mining cleanup first so a prior boost for this referral that ended when they went
        inactive is completed; the miner can then start a new boost row on a later active spell
        within the same base mining session.
        """
        from fastapi import HTTPException

        # Finalize any referral boosts for referrals who went inactive, so a new boost can
        # be started on the next active spell within the same base mining session.
        await SessionManager.cleanup_user_mining_sessions(user_id, db)
        
        # 1. Verify referral
        result = await db.execute(select(models.User).where(models.User.id == referral_id))
        referral = result.scalars().first()
        
        if not referral:
            raise HTTPException(status_code=404, detail="Referral not found")
            
        if referral.referred_by != user_referral_code:
            raise HTTPException(status_code=400, detail="User is not your referral")
            
        # 2. Referral must be actively mining (active BASE session on their account)
        if not await SessionManager.referral_user_has_active_base_mining(
            referral.id, db
        ):
            raise HTTPException(
                status_code=400,
                detail="Referral is not actively mining",
            )
            
        # 3. Check existing boost
        result = await db.execute(
            select(models.MiningSession)
            .where(models.MiningSession.user_id == user_id)
            .where(models.MiningSession.session_type == models.SessionType.REFERRAL_BOOST)
            .where(models.MiningSession.mining_for == referral_id)
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time > datetime.utcnow())
        )
        existing = result.scalars().first()
        
        if existing:
            raise HTTPException(status_code=400, detail="Boost already active for this referral")
            
        # 4. Get active base session to sync end time
        result = await db.execute(
            select(models.MiningSession)
            .where(models.MiningSession.user_id == user_id)
            .where(models.MiningSession.session_type == models.SessionType.BASE)
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time > datetime.utcnow())
        )
        base_session = result.scalars().first()
        
        if not base_session:
            raise HTTPException(status_code=400, detail="No active mining session found. Start mining first.")

        config = await SessionManager.get_admin_config(db)

        # Calculate proportional target reward based on base yield and referral boost percentage
        base_r_usd = 0.05 * (SessionManager.admin_catoshi_yield_pct(config) / 100.0)
        r_usd = base_r_usd * (SessionManager.admin_referral_boost_pct(config) / 100.0)
        if r_usd <= 0:
            r_usd = 0.005 # Minimum $0.005
            
        p_usd = await price_service.get_cat_price_usd(db)
        y, t = SessionManager.compute_rate(p_usd, r_usd)

        # 5. Create session synced with base session
        session = models.MiningSession(
            user_id=user_id,
            session_type=models.SessionType.REFERRAL_BOOST,
            mining_for=referral_id,
            start_time=datetime.utcnow(),
            end_time=base_session.end_time, # Sync with base session
            status=models.MiningStatus.ACTIVE,
            reward_y=y,
            reward_t=t,
            total_earned=0
        )
        
        db.add(session)
        await db.commit()
        await db.refresh(session)
        
        return session

    @staticmethod
    async def create_game_boost_session(user_id: str, boost_id: uuid.UUID, db: AsyncSession) -> models.MiningSession:
        """Activate a game boost from inventory and start a synced mining session"""
        from fastapi import HTTPException
        
        # 1. Get boost from inventory
        result = await db.execute(
            select(models.UserGameBoost)
            .where(models.UserGameBoost.id == boost_id)
            .where(models.UserGameBoost.user_id == user_id)
            .where(models.UserGameBoost.is_used == False)
        )
        boost = result.scalars().first()
        
        if not boost:
            raise HTTPException(status_code=404, detail="Available game boost not found")
            
        # 2. Get active base session to sync end time
        result = await db.execute(
            select(models.MiningSession)
            .where(models.MiningSession.user_id == user_id)
            .where(models.MiningSession.session_type == models.SessionType.BASE)
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time > datetime.utcnow())
        )
        base_session = result.scalars().first()
        
        if not base_session:
            raise HTTPException(status_code=400, detail="No active mining session found. Start mining first.")

        config = await SessionManager.get_admin_config(db)

        # 3. Calculate rate: (base_yield * boost_percentage)
        base_r_usd = 0.05 * (SessionManager.admin_catoshi_yield_pct(config) / 100.0)
        r_usd = base_r_usd * (boost.percentage / 100.0)
        
        p_usd = await price_service.get_cat_price_usd(db)
        y, t = SessionManager.compute_rate(p_usd, r_usd)

        # 4. Create boost session
        now = datetime.utcnow()
        # Duration is limited by BOTH the boost's max duration and the base session's end time
        boost_end_time = min(now + timedelta(minutes=boost.duration_minutes), base_session.end_time)
        
        session = models.MiningSession(
            user_id=user_id,
            session_type=models.SessionType.GAME_BOOST,
            start_time=now,
            end_time=boost_end_time,
            status=models.MiningStatus.ACTIVE,
            reward_y=y,
            reward_t=t,
            total_earned=0
        )
        
        db.add(session)
        await db.flush() # Get session ID
        
        # 5. Mark boost as used
        boost.is_used = True
        boost.session_id = session.id
        
        await db.commit()
        await db.refresh(session)
        
        return session

    @staticmethod
    async def close_referral_boosts_for_inactive_referrals(
        user_id: str, db: AsyncSession
    ) -> int:
        """
        End REFERRAL_BOOST sessions on the miner when the referred user no longer has an
        active BASE mining session (they stopped mining / session completed).
        """
        now = datetime.utcnow()
        RefBase = aliased(models.MiningSession)
        result = await db.execute(
            select(models.MiningSession)
            .join(models.User, models.MiningSession.mining_for == models.User.id)
            .outerjoin(
                RefBase,
                and_(
                    RefBase.user_id == models.User.id,
                    RefBase.session_type == models.SessionType.BASE,
                    RefBase.status == models.MiningStatus.ACTIVE,
                    RefBase.end_time > now,
                ),
            )
            .where(models.MiningSession.user_id == user_id)
            .where(
                models.MiningSession.session_type == models.SessionType.REFERRAL_BOOST
            )
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time > now)
            .where(RefBase.id.is_(None))
        )
        stale = result.scalars().all()
        for s in stale:
            s.end_time = now
        if stale:
            await db.commit()
        return len(stale)

    @staticmethod
    async def cleanup_user_mining_sessions(
        user_id: str, db: AsyncSession
    ) -> List[models.MiningSession]:
        """Expire-by-time completions, then end referral boosts for inactive referrals, then complete again."""
        completed: List[models.MiningSession] = []
        completed.extend(await SessionManager.complete_expired_sessions(user_id, db))
        await SessionManager.close_referral_boosts_for_inactive_referrals(user_id, db)
        completed.extend(await SessionManager.complete_expired_sessions(user_id, db))
        return completed

    @staticmethod
    async def complete_expired_sessions(user_id: str, db: AsyncSession) -> List[models.MiningSession]:
        """Complete expired sessions and update daily aggregated ledger"""
        
        # 1. Find expired sessions that haven't been completed
        result = await db.execute(
            select(models.MiningSession)
            .where(models.MiningSession.user_id == user_id)
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time <= datetime.utcnow())
            .where(models.MiningSession.completed_at.is_(None))
        )
        expired_sessions = result.scalars().all()
        
        if not expired_sessions:
            return []
        
        # 2. Get user and config
        user_result = await db.execute(select(models.User).where(models.User.id == user_id))
        user = user_result.scalars().first()
        
        if not user:
            return []
        
        config = await SessionManager.get_admin_config(db)
        
        # 3. Group sessions by type
        today = datetime.utcnow().date()
        base_sessions = []
        boost_sessions = []
        game_boost_sessions = [] # New list for game boosts
        total_earned = 0
        
        # Calculate earnings for each session
        for session in expired_sessions:
            elapsed_time = int((session.end_time - session.start_time).total_seconds())
            
            # Strict integer Y/T math, multiplying first for smooth per-second linear accumulation
            final_earned = (elapsed_time * session.reward_y) // session.reward_t
            total_earned += final_earned
            
            # Mark as completed
            session.status = models.MiningStatus.COMPLETED
            session.total_earned = final_earned
            session.completed_at = datetime.utcnow()
            
            if session.session_type == models.SessionType.BASE:
                base_sessions.append(session)
            elif session.session_type == models.SessionType.GAME_BOOST:
                game_boost_sessions.append(session)
            else:
                boost_sessions.append(session)
        
        # 4. Create/update aggregated ledger entries
        if base_sessions:
            await EarningsManager.add_to_daily_mining_ledger(
                user_id=user_id,
                date=today,
                reward_type=models.RewardType.MINING_BASE,
                sessions=base_sessions,
                db=db
            )
        
        if boost_sessions:
            await EarningsManager.add_to_daily_mining_ledger(
                user_id=user_id,
                date=today,
                reward_type=models.RewardType.MINING_REFERRAL_BOOST,
                sessions=boost_sessions,
                db=db
            )
        
        if game_boost_sessions:
            await EarningsManager.add_to_daily_mining_ledger(
                user_id=user_id,
                date=today,
                reward_type=models.RewardType.GAME_BOOST,
                sessions=game_boost_sessions,
                db=db
            )
        
        # 5. Update user balance
        # user.balance += total_earned

        # Referral milestone bonus (referee progress)
        from services.referral_bonus import recalculate_for_referee

        seen_referees = {s.user_id for s in expired_sessions}
        for rid in seen_referees:
            await recalculate_for_referee(db, rid, trigger="mining_event")

        await db.commit()

        print(f"Completed {len(expired_sessions)} sessions, earned {total_earned} Catoshis")
        
        return expired_sessions

class EarningsManager:
    """Manages earnings ledger and calculations"""
    
    @staticmethod
    async def get_user_balance(user_id: str, db: AsyncSession) -> float:
        """Calculate total user balance from ledger (Source of Truth)"""
        result = await db.execute(
            select(func.sum(models.EarningsLedger.amount))
            .where(models.EarningsLedger.user_id == user_id)
        )
        total = result.scalar()
        return float(total) if total else 0.0

    @staticmethod
    async def add_to_daily_mining_ledger(
        user_id: str,
        date: datetime.date,
        reward_type: models.RewardType,
        sessions: List[models.MiningSession],
        db: AsyncSession
    ):
        """Add sessions to daily aggregated ledger entry"""
        
        # Find or create daily ledger for this type
        result = await db.execute(
            select(models.EarningsLedger)
            .where(models.EarningsLedger.user_id == user_id)
            .where(models.EarningsLedger.aggregation_date == date)
            .where(models.EarningsLedger.reward_type == reward_type)
        )
        ledger = result.scalars().first()
        
        if not ledger:
            ledger = models.EarningsLedger(
                user_id=user_id,
                aggregation_date=date,
                amount=0.0,
                reward_type=reward_type
            )
            db.add(ledger)
            await db.flush()  # Get ID without committing
        
        # Add sessions to ledger
        for session in sessions:
            ledger.amount += session.total_earned
            session.ledger_entry_id = ledger.id
            
            # Create mapping
            mapping = models.LedgerSessionMapping(
                ledger_entry_id=ledger.id,
                session_id=session.id,
                session_contribution=session.total_earned
            )
            db.add(mapping)
        
        # Update User denormalized balance and total_earnings
        res = await db.execute(select(models.User).where(models.User.id == user_id))
        user = res.scalars().first()
        if user:
            total_sessions_earned = sum(session.total_earned for session in sessions)
            user.balance = (user.balance or 0.0) + total_sessions_earned
            user.total_earnings = (user.total_earnings or 0.0) + total_sessions_earned
            db.add(user)
    
    @staticmethod
    async def create_reward_entry(
        user_id: str,
        amount: float,
        reward_type: models.RewardType,
        description: str,
        db: AsyncSession,
        commit: bool = True,
        referral_id: Optional[uuid.UUID] = None,
    ) -> models.EarningsLedger:
        """Create individual reward entry (non-mining). Updates user balance in the same transaction."""
        entry = models.EarningsLedger(
            user_id=user_id,
            amount=amount,
            reward_type=reward_type,
            description=description,
            aggregation_date=None,
            referral_id=referral_id,
        )
        db.add(entry)
        await db.flush()
        await db.refresh(entry)

        res = await db.execute(select(models.User).where(models.User.id == user_id))
        user = res.scalars().first()
        if user:
            user.balance = (user.balance or 0.0) + amount
            user.total_earnings = (user.total_earnings or 0.0) + amount
            db.add(user)

        if commit:
            await db.commit()
            await db.refresh(entry)

        return entry
    
    @staticmethod
    async def create_withdrawal_entry(
        user_id: str,
        amount: float,
        payout_id: str,
        db: AsyncSession
    ) -> models.EarningsLedger:
        """Create withdrawal entry (negative amount)"""
        
        entry = models.EarningsLedger(
            user_id=user_id,
            amount=-abs(amount),  # Ensure negative
            reward_type=models.RewardType.WITHDRAWAL,
            payout_id=payout_id,
            description=f"Withdrawal to payout {payout_id}",
            aggregation_date=None
        )
        db.add(entry)
        await db.commit()
        await db.refresh(entry)
        
        # Update User denormalized balance (withdrawals don't affect total_earnings)
        res = await db.execute(select(models.User).where(models.User.id == user_id))
        user = res.scalars().first()
        if user:
            user.balance = (user.balance or 0.0) - abs(amount)
            db.add(user)
            
        return entry
    
    @staticmethod
    async def append_earnings(
        user_id: str,
        amount: float,
        reward_type: models.RewardType,
        db: AsyncSession,
        is_verified: bool = False,
        payout_id: Optional[str] = None
    ) -> models.EarningsLedger:
        """Add earnings ledger entry (legacy method for compatibility)"""
        entry = models.EarningsLedger(
            user_id=user_id,
            amount=amount,
            reward_type=reward_type,
            is_verified=is_verified,
            payout_id=payout_id
        )
        db.add(entry)
        await db.commit()
        await db.refresh(entry)
        
        # Update User denormalized balance and total_earnings
        res = await db.execute(select(models.User).where(models.User.id == user_id))
        user = res.scalars().first()
        if user:
            user.balance = (user.balance or 0.0) + amount
            user.total_earnings = (user.total_earnings or 0.0) + amount
            db.add(user)
            
        return entry
    
    @staticmethod
    async def calculate_earnings_breakdown(user_id: str, db: AsyncSession) -> Dict[str, float]:
        """Calculate total earnings per reward type"""
        result = await db.execute(
            select(
                models.EarningsLedger.reward_type,
                func.sum(models.EarningsLedger.amount)
            )
            .where(models.EarningsLedger.user_id == user_id)
            .group_by(models.EarningsLedger.reward_type)
        )
        
        breakdown = {rt.value: 0.0 for rt in models.RewardType}
        for reward_type, total in result.all():
            # Handle potential string return from DB driver vs Enum object
            key = reward_type.value if hasattr(reward_type, 'value') else reward_type
            if key in breakdown:
                breakdown[key] = float(total)
        
        return breakdown
    
    @staticmethod
    async def calculate_totals(user_id: str, db: AsyncSession) -> tuple:
        """Calculate total verified and unverified earnings"""
        result = await db.execute(
            select(func.sum(models.EarningsLedger.amount))
            .where(models.EarningsLedger.user_id == user_id)
            .where(models.EarningsLedger.is_verified == True)
        )
        verified = result.scalar() or 0.0
        
        result = await db.execute(
            select(func.sum(models.EarningsLedger.amount))
            .where(models.EarningsLedger.user_id == user_id)
            .where(models.EarningsLedger.is_verified == False)
        )
        unverified = result.scalar() or 0.0
        
        return float(verified), float(unverified)
