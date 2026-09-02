import asyncio
from sqlalchemy import text
from database import AsyncSessionLocal, async_engine

async def update_schema():
    try:
        async with AsyncSessionLocal() as db:
            print("🚀 Starting Withdrawal Permissions Migration...")
            
            # 1. Add global_withdrawal_enabled to admin_config
            try:
                print("Step 1: Adding global_withdrawal_enabled to admin_config...")
                await db.execute(text("ALTER TABLE admin_config ADD COLUMN global_withdrawal_enabled BOOLEAN DEFAULT TRUE"))
                await db.commit()
                print("✅ Added column: global_withdrawal_enabled")
            except Exception as e:
                await db.rollback()
                if "already exists" in str(e).lower():
                    print("ℹ️ Column global_withdrawal_enabled already exists.")
                else:
                    print(f"❌ Error adding column to admin_config: {str(e)}")
            
            # 2. Reset all withdrawal permissions for existing users
            try:
                print("Step 2: Resetting all existing user withdrawal permissions to False...")
                # We do this once to ensure "Default-OFF" applies to everyone currently in the system
                await db.execute(text("""
                    UPDATE users 
                    SET can_withdraw_mining = FALSE, 
                        can_withdraw_referrals = FALSE, 
                        can_withdraw_missions = FALSE, 
                        can_withdraw_games = FALSE
                """))
                await db.commit()
                print("✅ All existing user permissions reset to False.")
            except Exception as e:
                await db.rollback()
                print(f"❌ Error resetting user permissions: {str(e)}")
                
            print("🏁 Withdrawal permissions migration complete.")
    except Exception as e:
        print(f"FAILED: {str(e)}")
    finally:
        await async_engine.dispose()

if __name__ == "__main__":
    asyncio.run(update_schema())
