import os
import asyncio
import logging
from dotenv import load_dotenv
import httpx

# Configure basic logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger("DiscordCheck")

# Load environment variables
load_dotenv(dotenv_path="cat_poe_backend/.env")

DISCORD_BOT_TOKEN = os.getenv("DISCORD_BOT_TOKEN")
DISCORD_GUILD_ID = os.getenv("DISCORD_GUILD_ID")

async def verify_discord_config():
    print("--- Discord Bot Configuration Check ---")

    if not DISCORD_BOT_TOKEN:
        logger.error("❌ DISCORD_BOT_TOKEN is missing in .env")
        return
    
    if not DISCORD_GUILD_ID:
        logger.error("❌ DISCORD_GUILD_ID is missing in .env")
        return

    print(f"✅ Token Found: {DISCORD_BOT_TOKEN[:10]}...")
    print(f"✅ Guild ID Found: {DISCORD_GUILD_ID}")

    headers = {
        "Authorization": f"Bot {DISCORD_BOT_TOKEN}",
        "Content-Type": "application/json"
    }

    async with httpx.AsyncClient() as client:
        # 1. Check Bot Identity
        print("\nStep 1: Checking Bot Identity...")
        try:
            resp = await client.get("https://discord.com/api/v10/users/@me", headers=headers)
            if resp.status_code == 200:
                user_data = resp.json()
                print(f"✅ Bot Connected: {user_data.get('username')}#{user_data.get('discriminator')} (ID: {user_data.get('id')})")
            else:
                logger.error(f"❌ Failed to connect to Discord API. Status: {resp.status_code}. Msg: {resp.text}")
                return
        except Exception as e:
            logger.error(f"❌ Connection Error: {e}")
            return

        # 2. Check Guild Membership
        print(f"\nStep 2: Checking Membership in Guild {DISCORD_GUILD_ID}...")
        url = f"https://discord.com/api/v10/guilds/{DISCORD_GUILD_ID}"
        resp = await client.get(url, headers=headers)
        
        if resp.status_code == 200:
            guild_data = resp.json()
            print(f"✅ Bot is present in Guild: '{guild_data.get('name')}'")
        elif resp.status_code == 404:
            logger.error(f"❌ Guild {DISCORD_GUILD_ID} not found. Ensure the Bot is invited to this server!")
            return
        elif resp.status_code == 403:
            logger.error("❌ Access Forbidden. Bot might be missing permissions.")
            return
        else:
            logger.error(f"❌ Unexpected Error: {resp.text}")
            return

        # 3. Check Privileged Gateway Intent (Server Members)
        print("\nStep 3: Checking 'Server Members Intent' (Member Search Capability)...")
        # We try to search for a common letter 'a' to see if we get a list back.
        search_url = f"https://discord.com/api/v10/guilds/{DISCORD_GUILD_ID}/members/search"
        params = {"query": "a", "limit": 1}
        
        resp = await client.get(search_url, headers=headers, params=params)
        
        if resp.status_code == 200:
            print("✅ Member Search Successful! 'Server Members Intent' is active.")
        elif resp.status_code == 403:
            print("❌ Permission Denied on Member Search.")
            print("❗ ACTION REQUIRED: You must enable 'SERVER MEMBERS INTENT' in the Discord Developer Portal.")
            print("   See discord_bot_setup.md for instructions.")
        else:
            print(f"⚠️  Unexpected response on search: {resp.status_code} - {resp.text}")

    print("\n--- Check Complete ---")

if __name__ == "__main__":
    asyncio.run(verify_discord_config())
