import os
import asyncio
import logging
import httpx
from dotenv import load_dotenv

# Configure basic logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger("TwitterCheck")

# Load environment variables
load_dotenv(dotenv_path="cat_poe_backend/.env")

X_BEARER_TOKEN = os.getenv("X_BEARER_TOKEN")
X_COMMUNITY_USERNAME = os.getenv("X_COMMUNITY_USERNAME", "").strip()

async def verify_twitter_config():
    print("--- X (Twitter) Configuration Check ---")

    if not X_BEARER_TOKEN:
        logger.error("❌ X_BEARER_TOKEN is missing in .env")
        print("Please follow the instructions in twitter_setup.md to get your token.")
        return

    if not X_COMMUNITY_USERNAME:
        logger.error("❌ X_COMMUNITY_USERNAME is missing in .env (no default; set your community / lookup username).")
        return
    
    print(f"✅ Bearer Token Found: {X_BEARER_TOKEN[:10]}...")
    print(f"✅ Target Community: @{X_COMMUNITY_USERNAME}")

    headers = {
        "Authorization": f"Bearer {X_BEARER_TOKEN}",
        "Content-Type": "application/json"
    }

    async with httpx.AsyncClient() as client:
        # 1. Check Identity (Me) - Not always available with App-only Bearer Token on Free tier?
        # Actually, /2/users/me requires User Context (OAuth 2.0). 
        # With App-only Bearer Token, we should try to lookup a random user (e.g. the community account).
        
        print(f"\nStep 1: Verifying Token by looking up @{X_COMMUNITY_USERNAME}...")
        url = f"https://api.twitter.com/2/users/by/username/{X_COMMUNITY_USERNAME}"
        
        try:
            resp = await client.get(url, headers=headers)
            
            if resp.status_code == 200:
                data = resp.json()
                if "data" in data:
                    user = data["data"]
                    print(f"✅ Success! Found user: {user['name']} (@{user['username']}) - ID: {user['id']}")
                else:
                    # User not found but token worked
                    print(f"⚠️  Token works, but user @{X_COMMUNITY_USERNAME} was not found.")
                    print(f"   API Response: {data}")
            elif resp.status_code == 401:
                logger.error("❌ Unauthorized. Your Bearer Token is invalid.")
            elif resp.status_code == 403:
                logger.error("❌ Forbidden. Your app may not have access to this endpoint (Standard Free Tier Issue).")
            elif resp.status_code == 429:
                logger.warning("⚠️  Rate Limit Exceeded. Try again in 15 minutes.")
            else:
                logger.error(f"❌ Unexpected Error: {resp.status_code} - {resp.text}")

        except Exception as e:
            logger.error(f"❌ Connection Error: {e}")

    print("\n--- Check Complete ---")

if __name__ == "__main__":
    asyncio.run(verify_twitter_config())
