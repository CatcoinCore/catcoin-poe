import os
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import models
import auth
import uuid

async def create_root_user(db: AsyncSession):
    """Ensure root admin user exists.

    When creating the initial ``root`` user, requires ``ROOT_BOOTSTRAP_PASSWORD`` and
    ``ROOT_BOOTSTRAP_EMAIL`` in the environment. No default credentials are provided.
    """
    result = await db.execute(select(models.User).where(models.User.username == "root"))
    user = result.scalars().first()
    
    if not user:
        password = os.getenv("ROOT_BOOTSTRAP_PASSWORD", "").strip()
        email = os.getenv("ROOT_BOOTSTRAP_EMAIL", "").strip()
        if not password or not email:
            print(
                "Skipping root user creation: set ROOT_BOOTSTRAP_PASSWORD and "
                "ROOT_BOOTSTRAP_EMAIL (see .env.example)."
            )
            return
        print("Creating root admin user...")
        hashed_password = auth.get_password_hash(password)
        referral_code = str(uuid.uuid4())[:8]
        
        user = models.User(
            username="root",
            email=email,
            display_name="Root Admin",
            hashed_password=hashed_password,
            referral_code=referral_code,
            is_admin=True,
            balance=1000.0,
            email_verified=True
        )
        db.add(user)
        await db.commit()
        print("Root user created successfully.")
    else:
        # Ensure is_admin is true
        if not user.is_admin:
            user.is_admin = True
            await db.commit()
            print("Updated root user to be admin.")

if __name__ == "__main__":
    import asyncio
    from database import AsyncSessionLocal, async_engine
    
    async def main():
        try:
            async with AsyncSessionLocal() as db:
                await create_root_user(db)
        finally:
            await async_engine.dispose()
            
    asyncio.run(main())
