import os
import asyncio
import logging
import httpx
from dotenv import load_dotenv

# Configure basic logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger("TelegramCheck")

# Load environment variables
load_dotenv(dotenv_path="cat_poe_backend/.env")

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

async def verify_telegram_config():
    print("--- Telegram Configuration Check ---")

    if not TELEGRAM_BOT_TOKEN:
        logger.error("❌ TELEGRAM_BOT_TOKEN is missing in .env")
        return
    
    if not TELEGRAM_CHAT_ID:
        logger.error("❌ TELEGRAM_CHAT_ID is missing in .env")
        return

    print(f"✅ Bot Token Found: {TELEGRAM_BOT_TOKEN[:10]}...")
    print(f"✅ Chat ID Found: {TELEGRAM_CHAT_ID}")

    async with httpx.AsyncClient() as client:
        # 1. Check Bot Identity (getMe)
        print("\nStep 1: Checking Bot Identity...")
        url_me = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/getMe"
        
        try:
            resp = await client.get(url_me)
            data = resp.json()
            
            if resp.status_code == 200 and data.get("ok"):
                bot_user = data["result"]
                print(f"✅ Bot Connected: {bot_user['first_name']} (@{bot_user['username']}) - ID: {bot_user['id']}")
            else:
                logger.error(f"❌ Failed to connect to Telegram API. Error: {data.get('description', 'Unknown')}")
                return

        except Exception as e:
            logger.error(f"❌ Connection Error: {e}")
            return

        # 2. Check Chat Access (getChat)
        print(f"\nStep 2: Checking Access to Chat '{TELEGRAM_CHAT_ID}'...")
        url_chat = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/getChat"
        params = {"chat_id": TELEGRAM_CHAT_ID}

        try:
            resp = await client.get(url_chat, params=params)
            data = resp.json()

            if resp.status_code == 200 and data.get("ok"):
                chat = data["result"]
                title = chat.get("title", "No Title")
                c_type = chat.get("type", "unknown")
                print(f"✅ Bot can see the {c_type}: '{title}' (ID: {chat['id']})")
                
                # Check permissions if possible? 
                # getChatMember for the bot itself to see if it's admin
                bot_id = bot_user['id']
                url_member = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/getChatMember"
                params_member = {"chat_id": TELEGRAM_CHAT_ID, "user_id": bot_id}
                
                resp_mem = await client.get(url_member, params=params_member)
                data_mem = resp_mem.json()
                if data_mem.get("ok"):
                    status = data_mem["result"]["status"]
                    print(f"ℹ️  Bot Status in Chat: {status.upper()}")
                    if status == "administrator":
                        print("✅ Bot is correctly set as Administrator.")
                    else:
                         print("⚠️  Bot is NOT an Administrator. Verification might fail if member lists are hidden.")
                         print("   Please promote the bot to Administrator.")

            else:
                err_msg = data.get('description', 'Unknown Error')
                logger.error(f"❌ Failed to access Chat. Error: {err_msg}")
                if "chat not found" in err_msg.lower():
                    print("   - Verify the Chat ID/Username is correct.")
                    print("   - If public, does it have a username?")
                    print("   - If private, is the bot added to the group?")
                if "unauthorized" in err_msg.lower():
                     print("   - Bot might not be a member of the chat.")

        except Exception as e:
            logger.error(f"❌ Connection Error during Chat check: {e}")

    print("\n--- Check Complete ---")

if __name__ == "__main__":
    asyncio.run(verify_telegram_config())
