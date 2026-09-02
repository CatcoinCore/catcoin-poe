"""
Database migration for email-based authentication
Adds email, display_name, and email verification fields to users table
"""
import asyncio
import os
from sqlalchemy import text


from database import AsyncSessionLocal, async_engine

async def run_migration():
    try:
        async with AsyncSessionLocal() as db:
            print("Starting email auth migration...")
            
            # Add new columns to users table
            columns_to_add = [
                ("email", "VARCHAR UNIQUE"),
                ("display_name", "VARCHAR"),
                ("email_verified", "BOOLEAN DEFAULT FALSE"),
                ("verification_code", "VARCHAR(6)"),
                ("verification_code_expires", "TIMESTAMP")
            ]
            
            for col_name, col_type in columns_to_add:
                try:
                    await db.execute(text(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}"))
                    await db.commit()
                    print(f"✓ Added column: {col_name}")
                except Exception as e:
                    await db.rollback()
                    print(f"Column {col_name} might already exist: {str(e)[:100]}")
            
            # Create index on email for faster lookups
            try:
                await db.execute(text("CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)"))
                await db.commit()
                print("✓ Created email index")
            except Exception as e:
                await db.rollback()
                print(f"Email index might already exist: {e}")
            
            # Update existing users
            try:
                # Set email_verified = TRUE for existing users
                result = await db.execute(text("UPDATE users SET email_verified = TRUE WHERE email_verified IS NULL"))
                await db.commit()
                print(f"✓ Updated {result.rowcount} existing users to verified")
                
                # Set display_name = username for existing users (where display_name is null)
                result = await db.execute(text("UPDATE users SET display_name = username WHERE display_name IS NULL"))
                await db.commit()
                print(f"✓ Set display_name for {result.rowcount} existing users")
                
            except Exception as e:
                await db.rollback()
                print(f"Error updating existing users: {e}")
            
            print("Migration complete!")
    finally:
        await async_engine.dispose()

if __name__ == "__main__":
    asyncio.run(run_migration())
