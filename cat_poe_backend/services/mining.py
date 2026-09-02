from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import desc
import models, schemas

class MiningService:
    SESSION_DURATION_HOURS = 4
    BASE_HASHRATE = 1.0
    REFERRAL_BOOST = 0.1

    @staticmethod
    async def get_active_session(user_id: str, db: AsyncSession) -> models.MiningSession | None:
        result = await db.execute(
            select(models.MiningSession)
            .where(models.MiningSession.user_id == user_id)
            .where(models.MiningSession.status == models.MiningStatus.ACTIVE)
            .where(models.MiningSession.end_time > datetime.utcnow())
        )
        return result.scalars().first()

    @staticmethod
    async def start_session(user_id: str, db: AsyncSession) -> models.MiningSession:
        # Check for active session
        active_session = await MiningService.get_active_session(user_id, db)
        if active_session:
            raise ValueError("Mining session already active")

        now = datetime.utcnow()
        end_time = now + timedelta(hours=MiningService.SESSION_DURATION_HOURS)
        
        session = models.MiningSession(
            user_id=user_id,
            start_time=now,
            end_time=end_time,
            status=models.MiningStatus.ACTIVE
        )
        db.add(session)
        await db.commit()
        await db.refresh(session)
        return session

    @staticmethod
    async def get_stats(user: models.User, db: AsyncSession) -> schemas.StatsResponse:
        # Calculate hashrate based on referrals (mock logic for referrals count)
        # In a real app, we'd count actual referrals. For now, let's assume 0 or query if we had a referral table link.
        # The User model has referral_code, but we need to count users who used this code.
        # Let's add a query for referral count.
        
        # Count users where referral_code matches this user's referral_code? 
        # Wait, the User model doesn't store "referred_by". 
        # Prompt 1 didn't ask for "referred_by" field in User model.
        # Prompt 3 says "Users get a speed boost for every active referral".
        # I should probably add `referred_by` to User model to track this, or just mock it for now as 0.
        # The prompt says "Referrals: Users get a speed boost for every active referral."
        # I will check if I can add `referred_by` to User model. 
        # Prompt 1 User model: id, username, hashed_password, referral_code, created_at.
        # It missed `referred_by`. I should add it now or in a later prompt?
        # Prompt 8 is "Wallet & Referrals".
        # For now, I'll assume 0 referrals or just mock it.
        # I'll add a TODO to implement referral counting properly.
        
        referral_count = 0 # Placeholder
        hashrate = MiningService.BASE_HASHRATE + (referral_count * MiningService.REFERRAL_BOOST)
        
        active_session = await MiningService.get_active_session(user.id, db)
        
        # Balance calculation (mock)
        # In a real app, we'd sum up rewards from completed sessions.
        balance = 0.0 
        
        return schemas.StatsResponse(
            balance=balance,
            hashrate=hashrate,
            active_session=active_session
        )
