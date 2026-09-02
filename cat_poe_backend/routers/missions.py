from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks, Header
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import models, schemas, database, auth
from services.social_lock_service import (
    apply_social_verified_and_locked,
    platform_from_mission_icon,
    write_audit,
)

router = APIRouter(
    prefix="/missions",
    tags=["missions"],
)

@router.get("/", response_model=list[schemas.MissionResponse])
async def list_missions(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    # 1. Get all active missions, sorted by Created At DESC (Latest first)
    # Filter out expired missions
    # Note: expires_at IS NULL OR expires_at > NOW
    now = datetime.utcnow()
    query = (
        select(models.Mission)
        .where(models.Mission.is_active == True)
        .where((models.Mission.expires_at == None) | (models.Mission.expires_at > now))
        .order_by(models.Mission.created_at.desc().nulls_last()) # Ensure new fields sort correctly
    )
    result = await db.execute(query)
    missions = result.scalars().all()
    
    # 2. Get user completed/pending missions
    result = await db.execute(
        select(models.UserMission)
        .where(models.UserMission.user_id == user.id)
    )
    user_missions = result.scalars().all()
    
    # Map mission_id -> status
    mission_status_map = {um.mission_id: um.status for um in user_missions}
    
    # Set of completed mission IDs (for prerequisite check)
    completed_mission_ids = {um.mission_id for um in user_missions if um.status == "COMPLETED"}
    
    response = []
    for mission in missions:
        # 3. Check Prerequisite
        if mission.prerequisite_id:
            # If prerequisite is NOT in completed list, hide the mission
            if mission.prerequisite_id not in completed_mission_ids:
                continue
        
        status = mission_status_map.get(mission.id)
        
        response.append({
            "id": str(mission.id),
            "code": mission.code,
            "title": mission.title,
            "description": mission.description,
            "link": mission.link,
            "icon": mission.icon,
            "type": mission.type.value if mission.type else None,
            "reward_amount": mission.reward_amount,
            "is_active": mission.is_active,
            "expires_at": mission.expires_at,
            "prerequisite_id": str(mission.prerequisite_id) if mission.prerequisite_id else None,
            "created_at": mission.created_at,
            "status": status,
            "is_completed": status == "COMPLETED"
        })
        
    return response

@router.post("/complete")
async def complete_mission(
    mission: schemas.MissionComplete,
    background_tasks: BackgroundTasks,
    x_client_env: str = Header("release", alias="X-Client-Env"),
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    # Capture user attributes upfront to avoid MissingGreenlet after commits
    user_id = user.id
    user_balance = user.balance
    
    # Find mission by code
    result = await db.execute(select(models.Mission).where(models.Mission.code == mission.code))
    db_mission = result.scalars().first()
    if not db_mission:
        raise HTTPException(status_code=404, detail="Mission not found")
    
    # Capture mission id for later use
    mission_id = db_mission.id
        
    # Check if already completed or pending
    result = await db.execute(
        select(models.UserMission)
        .where(models.UserMission.user_id == user_id)
        .where(models.UserMission.mission_id == mission_id)
    )
    existing = result.scalars().first()
    
    user_mission = None
    
    if existing:
        if existing.status == "COMPLETED":
             raise HTTPException(status_code=400, detail="Mission already completed")
        elif existing.status == "PENDING":
             raise HTTPException(status_code=400, detail="Verification already in progress")
        # If status is FAILED or REJECTED, we allow retry by updating the existing record
        user_mission = existing
        # Reset relevant fields for retry
        user_mission.verification_proof = mission.verification_data
        user_mission.completed_at = None
        # status will be set below

    # Determine status based on mission type
    # Social missions (Discord/Telegram) go to PENDING + Background Task
    # Others (X/Twitter) might still be instant or manual-check in future
    
    mission_type = (db_mission.icon or "").lower()
    is_async_verification = "discord" in mission_type or "telegram" in mission_type or "twitter" in mission_type or "x" in mission_type
    
    try:
        if is_async_verification:
            # Create or Update PENDING entry
            if not user_mission:
                user_mission = models.UserMission(
                    user_id=user_id, 
                    mission_id=mission_id,
                    status="PENDING",
                    verification_proof=mission.verification_data,
                    completed_at=None
                )
                db.add(user_mission)
            else:
                user_mission.status = "PENDING"
            
            await db.commit()
            
            # Trigger Background Task
            from services.verification_task import verify_mission_background
            background_tasks.add_task(
                verify_mission_background, 
                str(user_id), 
                str(mission_id), 
                mission.verification_data,
                env=x_client_env
            )
            
            return {
                "message": "Verification started. Please ensure you have joined the channel/group.", 
                "status": "PENDING",
                "reward": 0.0,
                "new_balance": user_balance
            }
        
        else:
            # Legacy/Instant verification
            if not user_mission:
                user_mission = models.UserMission(
                    user_id=user_id,
                    mission_id=mission_id,
                    status="COMPLETED",
                    verification_proof=mission.verification_data,
                    completed_at=datetime.utcnow(),
                )
                db.add(user_mission)
            else:
                user_mission.status = "COMPLETED"
                user_mission.completed_at = datetime.utcnow()
                user_mission.verification_proof = mission.verification_data

            reward_amount = db_mission.reward_amount

            from services.session_manager import EarningsManager

            ures = await db.execute(select(models.User).where(models.User.id == user_id))
            urow = ures.scalars().first()
            await EarningsManager.create_reward_entry(
                user_id=user_id,
                amount=reward_amount,
                reward_type=models.RewardType.MISSION_COMPLETION,
                description=f"Completed mission: {db_mission.title} mission_id={mission_id}",
                db=db,
                commit=False,
            )
            if urow:
                apply_social_verified_and_locked(
                    urow, db_mission.icon, mission.verification_data
                )
                await write_audit(
                    db,
                    urow.id,
                    "REWARD_GRANTED",
                    platform_from_mission_icon(db_mission.icon),
                    f"mission_id={mission_id} code={db_mission.code}",
                    reward_amount,
                )

            await db.commit()
            if urow:
                await db.refresh(urow)

            nb = urow.balance if urow else user.balance
            return {
                "message": "Mission completed",
                "status": "COMPLETED",
                "reward": reward_amount,
                "new_balance": nb,
            }

    except Exception as e:
        # Check for IntegrityError (unique violation) which means race condition or duplicate
        # Since we use asyncpg, it might be wrapped in SQLAlchemy errors
        error_str = str(e).lower()
        if "integrity" in error_str or "unique" in error_str:
             await db.rollback()
             # Check again to be sure what happened
             # But generally it means it was completed by another request
             raise HTTPException(status_code=409, detail="Mission update conflict. Please refresh and try again.")
        raise e
