import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from config import settings

# Database URL
DATABASE_URL = settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

async def update_schema():
    engine = create_async_engine(DATABASE_URL, echo=True)
    
    async with engine.begin() as conn:
        print("Checking for column 'ip_address' in 'users' table...")
        # Check if column exists
        result = await conn.execute(text(
            "SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='ip_address'"
        ))
        if not result.scalar():
            print("Adding 'ip_address' column...")
            await conn.execute(text("ALTER TABLE users ADD COLUMN ip_address VARCHAR"))
        else:
            print("'ip_address' column already exists.")

        print("Checking for column 'device_id' in 'users' table...")
        result = await conn.execute(text(
            "SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='device_id'"
        ))
        if not result.scalar():
            print("Adding 'device_id' column...")
            await conn.execute(text("ALTER TABLE users ADD COLUMN device_id VARCHAR"))
            await conn.execute(text("CREATE INDEX idx_users_device_id ON users (device_id)"))
        else:
            print("'device_id' column already exists.")

        print("Checking for column 'is_suspicious' in 'users' table...")
        result = await conn.execute(text(
            "SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='is_suspicious'"
        ))
        if not result.scalar():
            print("Adding 'is_suspicious' column...")
            await conn.execute(text("ALTER TABLE users ADD COLUMN is_suspicious BOOLEAN DEFAULT FALSE"))
        else:
            print("'is_suspicious' column already exists.")

        print("Checking for table 'suspicious_activities'...")
        result = await conn.execute(text(
            "SELECT table_name FROM information_schema.tables WHERE table_name='suspicious_activities'"
        ))
        if not result.scalar():
            print("Creating 'suspicious_activities' table...")
            await conn.execute(text("""
                CREATE TABLE suspicious_activities (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    user_id UUID NOT NULL REFERENCES users(id),
                    activity_type VARCHAR NOT NULL,
                    evidence VARCHAR NOT NULL,
                    related_user_id UUID REFERENCES users(id),
                    is_resolved BOOLEAN DEFAULT FALSE,
                    detected_at TIMESTAMP DEFAULT timezone('utc', now())
                )
            """))
            await conn.execute(text("CREATE INDEX idx_suspicious_activities_user ON suspicious_activities (user_id)"))
        else:
            print("'suspicious_activities' table already exists.")

    await engine.dispose()
    print("Schema update complete.")

if __name__ == "__main__":
    asyncio.run(update_schema())
