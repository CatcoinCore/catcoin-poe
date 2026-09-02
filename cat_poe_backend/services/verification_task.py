import asyncio
import logging
from datetime import datetime
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from database import AsyncSessionLocal
import models
from services.social_verification import SocialVerificationService
from services.session_manager import EarningsManager
from services.social_lock_service import (
    apply_social_verified_and_locked,
    platform_from_mission_icon,
    write_audit,
)

logger = logging.getLogger(__name__)

async def verify_mission_background(user_id: str, mission_id: str, verification_data: str, env: str = "release"):
    """
    Background task to verify social mission completion.
    Retries 5 times with increasing intervals: 2, 3, 5, 7, 10 minutes.
    """
    # Default delays
    delays = [120, 180, 300, 420, 600] 

    logger.info(f"Starting background verification for User {user_id}, Mission {mission_id}")

    # Use a while loop to handle dynamic retries/delays if we want, or just pre-fetch config?
    # Better: Fetch config once at start or fetch fresh each time? 
    # To support "admin changes config while task is running", we might need to fetch fresh.
    # But usually, it's fine to lock in the schedule at task start.
    
    # 0. Fetch Config for Delays (New)
    async with AsyncSessionLocal() as db:
        config_result = await db.execute(select(models.AdminConfig).order_by(models.AdminConfig.id.desc()))
        config = config_result.scalars().first()
        if config and config.verification_backoff_delays:
            try:
                import json
                loaded_delays = json.loads(config.verification_backoff_delays)
                if isinstance(loaded_delays, list) and all(isinstance(x, int) for x in loaded_delays):
                     delays = loaded_delays
                     logger.info(f"Loaded custom verification delays: {delays}")
            except Exception as e:
                logger.error(f"Failed to parse verification_backoff_delays: {e}. Using default.")
    
    retries = len(delays)

    for attempt, delay_seconds in enumerate(delays, 1):
        # Delay before this attempt
        logger.info(f"Waiting {delay_seconds}s before verification attempt {attempt}/{retries}")
        await asyncio.sleep(delay_seconds)
        
        async with AsyncSessionLocal() as db:
            try:
                # 1. Fetch Mission & capture attributes immediately
                result = await db.execute(select(models.Mission).where(models.Mission.id == mission_id))
                mission = result.scalars().first()
                if not mission:
                    logger.error(f"Mission {mission_id} not found during background verification.")
                    return
                
                # Capture mission attributes to avoid lazy loading
                mission_code = mission.code
                mission_icon = mission.icon
                mission_title = mission.title
                mission_reward = mission.reward_amount

                # 2. Check Global Verification Toggle
                # Determine environment and toggle status
                # (We re-fetch config here, effectively getting fresh toggle status)
                config_result = await db.execute(select(models.AdminConfig).order_by(models.AdminConfig.id.desc()))
                config = config_result.scalars().first()
                if not config:
                    is_enabled = True
                    # If config missing, we might default env check?
                else:
                    if env == "debug":
                        is_enabled = config.enable_verification_debug
                    else:
                        is_enabled = config.enable_verification_release
                
                is_verified = False
                
                if not is_enabled:
                     logger.info(f"Verification BYPASSED (Env: {env}) for User {user_id}")
                     is_verified = True
                else:
                    # 3. Perform Actual Verification
                    mission_type = (mission_icon or "").lower()
    
                    if "discord" in mission_type:
                        is_verified = await SocialVerificationService.verify_discord_membership(verification_data, db)
                    elif "telegram" in mission_type:
                        is_verified = await SocialVerificationService.verify_telegram_membership(verification_data, db)
                    elif "twitter" in mission_type or "x" in mission_type:
                        # Check if it's a specific Tweet (Retweet mission) or generic follow
                        mission_link = mission.link or ""
                        if "status/" in mission_link:
                             is_verified = await SocialVerificationService.verify_x_retweet(verification_data, mission_link, db, env=env)
                        else:
                             is_verified = await SocialVerificationService.verify_x_follow(verification_data, db, env=env)
                    else:
                        # Generic success for others
                        is_verified = True 

                # 3. Handle Result
                if is_verified:
                    await _mark_mission_completed(
                        db=db,
                        user_id=user_id,
                        mission_id=mission_id,
                        mission_title=mission_title,
                        mission_reward=mission_reward,
                        mission_icon=mission_icon,
                        proof=verification_data,
                    )
                    logger.info(f"Verification SUCCESS for User {user_id}, Mission {mission_code}")
                    return # Exit task
                else:
                    logger.warning(f"Verification FAILED (Attempt {attempt}/{retries}) for User {user_id}")
            
            except Exception as e:
                logger.error(f"Exception during verification attempt {attempt}: {e}")
                # Continue loop to retry
    
    # If loop finishes without success
    async with AsyncSessionLocal() as db:
        await _handle_final_failure(db, user_id, mission_id)
        logger.info(f"Verification finally FAILED after {retries} attempts.")

async def _mark_mission_completed(
    db: AsyncSession,
    user_id: str,
    mission_id: str,
    mission_title: str,
    mission_reward: float,
    mission_icon: Optional[str],
    proof: str,
):
    result = await db.execute(
        select(models.UserMission)
        .where(models.UserMission.user_id == user_id)
        .where(models.UserMission.mission_id == mission_id)
        .with_for_update()
    )
    user_mission = result.scalars().first()

    if user_mission:
        if user_mission.status == "COMPLETED":
            logger.warning(
                f"User {user_id} already completed Mission {mission_id}. Skipping reward."
            )
            return

        user_mission.status = "COMPLETED"
        user_mission.completed_at = datetime.utcnow()
        user_mission.verification_proof = proof
    else:
        user_mission = models.UserMission(
            user_id=user_id,
            mission_id=mission_id,
            status="COMPLETED",
            verification_proof=proof,
            completed_at=datetime.utcnow(),
        )
        db.add(user_mission)

    result = await db.execute(select(models.User).where(models.User.id == user_id))
    user = result.scalars().first()
    if user:
        actual_user_id = user.id
        await EarningsManager.create_reward_entry(
            user_id=actual_user_id,
            amount=mission_reward,
            reward_type=models.RewardType.MISSION_COMPLETION,
            description=f"Completed mission: {mission_title} mission_id={mission_id}",
            db=db,
            commit=False,
        )
        apply_social_verified_and_locked(user, mission_icon, proof)
        plat = platform_from_mission_icon(mission_icon)
        await write_audit(
            db,
            user.id,
            "REWARD_GRANTED",
            plat,
            f"mission_id={mission_id} title={mission_title}",
            mission_reward,
        )

    await db.commit()

async def _handle_final_failure(db: AsyncSession, user_id: str, mission_id: str):
    # Mark as FAILED or REJECTED so user can see it failed
    result = await db.execute(
        select(models.UserMission)
        .where(models.UserMission.user_id == user_id)
        .where(models.UserMission.mission_id == mission_id)
    )
    user_mission = result.scalars().first()
    
    if user_mission:
        user_mission.status = "FAILED"
        await db.commit()
