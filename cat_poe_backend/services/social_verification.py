import httpx
import os
import logging
from sqlalchemy.ext.asyncio import AsyncSession
from services.session_manager import SessionManager
from services.secret_crypto import decrypt_if_encrypted, SENSITIVE_ADMIN_CONFIG_FIELDS

logger = logging.getLogger(__name__)

class SocialVerificationService:
    @staticmethod
    async def get_config_value(db: AsyncSession, key_env: str, key_db_attr: str) -> str:
        # 1. Try Environment Variable first
        val = os.getenv(key_env)
        if val: 
            if "TOKEN" in key_env:
                logger.info(f"Loaded {key_env} from ENV: {val[:5]}... ({len(val)} chars)")
            return val
        
        # 2. Try Database Config
        try:
            config = await SessionManager.get_admin_config(db)
            db_val = getattr(config, key_db_attr, None)
            if db_val and key_db_attr in SENSITIVE_ADMIN_CONFIG_FIELDS:
                db_val = decrypt_if_encrypted(db_val)
            if db_val and "TOKEN" in key_env:
                 logger.info(f"Loaded {key_db_attr} from DB: {db_val[:5]}... ({len(db_val)} chars)")
            return db_val
        except Exception as e:
            logger.error(f"Error fetching DB config for {key_db_attr}: {e}")
            return None

    @staticmethod
    async def verify_discord_membership(username_or_id: str, db: AsyncSession) -> bool:
        """
        Verifies if a Discord User is a member of the configured Guild.
        Supports both User ID (numeric) and Username (search).
        """
        token = await SocialVerificationService.get_config_value(db, "DISCORD_BOT_TOKEN", "discord_bot_token")
        guild_id = await SocialVerificationService.get_config_value(db, "DISCORD_GUILD_ID", "discord_guild_id")
        
        if token: 
            token = token.strip()
            if token.lower().startswith("bot "):
                token = token[4:].strip()
                
        if guild_id: guild_id = guild_id.strip()

        if not token or not guild_id:
            logger.warning("Discord verification FAILED: Missing config (Env or DB)")
            return False # Fail strict

        # Clean input
        identifier = username_or_id.strip()
        
        headers = {
            "Authorization": f"Bot {token}",
            "Content-Type": "application/json"
        }
        
        # DEBUG: Log the token format to catch "Bot Bot ..." or empty strings
        safe_log_token = f"{token[:4]}...{token[-4:]}" if token and len(token) > 8 else "INVALID"
        logger.info(f"[Discord Debug] Verifying '{identifier}'. Token used: '{safe_log_token}' (Length: {len(token) if token else 0})")

        async with httpx.AsyncClient() as client:
            try:
                # Case 1: Numeric ID (Legacy support or explicit ID)
                if identifier.isdigit() and len(identifier) > 15:
                    url = f"https://discord.com/api/v10/guilds/{guild_id}/members/{identifier}"
                    logger.info(f"[Discord Debug] Executing URL (ID Check): {url}")
                    
                    response = await client.get(url, headers=headers)
                    if response.status_code == 200:
                        return True
                    elif response.status_code == 404:
                         # Fallback: Maybe their username is all numbers? unlikely but possible.
                         logger.info(f"[Discord Debug] ID Check 404, falling back to search.")
                         pass 
                    else:
                        logger.error(f"Discord API Error (ID Check): {response.text}")
                        return False

                # Case 2: Username Search
                search_url = f"https://discord.com/api/v10/guilds/{guild_id}/members/search"
                params = {"query": identifier, "limit": 10}
                
                logger.info(f"[Discord Debug] Executing URL (Search): {search_url} with params {params}")
                
                response = await client.get(search_url, headers=headers, params=params)
                
                if response.status_code == 200:
                    members = response.json()
                    # Check if any found member matches the username
                    for member in members:
                        user = member.get("user", {})
                        # Match against username (new unique usernames) or global_name or legacy discriminator
                        if (user.get("username", "").lower() == identifier.lower() or 
                            user.get("global_name", "").lower() == identifier.lower()):
                            return True
                    return False
                else:
                    logger.error(f"Discord API Error (Search): {response.text}")
                    return False

            except Exception as e:
                logger.error(f"Discord Verification Exception: {e}")
                return False

    @staticmethod
    async def verify_telegram_membership(username_or_id: str, db: AsyncSession) -> bool:
        """
        Verifies if a Telegram user is a member of the configured Channel/Group.
        Checks ENV then DB for config.
        """
        token = await SocialVerificationService.get_config_value(db, "TELEGRAM_BOT_TOKEN", "telegram_bot_token")
        chat_id = await SocialVerificationService.get_config_value(db, "TELEGRAM_CHAT_ID", "telegram_chat_id")
        
        if token: token = token.strip()
        if chat_id: chat_id = chat_id.strip()

        if not token or not chat_id:
            logger.warning("Telegram verification FAILED: Missing config")
            return False

        # Clean input
        user_identifier = username_or_id.strip()
        
        if not user_identifier.isdigit():
             logger.warning(f"Telegram verification FAILED: Input '{user_identifier}' is not a numeric ID.")
             return False 

        url = f"https://api.telegram.org/bot{token}/getChatMember"
        params = {
            "chat_id": chat_id,
            "user_id": user_identifier
        }

        # DEBUG: Log token snippet and URL info
        safe_token = f"{token[:5]}...{token[-5:]}" if len(token) > 10 else "SHORT/INVALID"
        logger.info(f"[Telegram Debug] Verifying user {user_identifier} in chat {chat_id}. URL: .../bot{safe_token}/getChatMember")

        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(url, params=params)
                
                # DEBUG: Log raw response
                logger.info(f"[Telegram Debug] API Status: {response.status_code}, Body: {response.text}")

                if response.status_code == 200:
                    data = response.json()
                    if data.get("ok"):
                        status = data["result"]["status"]
                        logger.info(f"[Telegram Debug] User status in chat: {status}")
                        if status in ["creator", "administrator", "member", "restricted"]:
                             return True
                        return False
                    else:
                        logger.error(f"Telegram API Error: {data}")
                        return False
                else:
                     logger.error(f"Telegram HTTP Error {response.status_code}: {response.text}")
                     return False
            except Exception as e:
                logger.error(f"Telegram Verification Exception: {e}")
                return False

    @staticmethod
    async def verify_x_follow(verification_data: str, db: AsyncSession, env: str = "release") -> bool:
        """
        Verifies if a user (via verification_data/handle) is following the official account.
        Uses env ("debug" or "release") to determine which toggle to check.
        """
        user_handle = verification_data.strip().replace("@", "")
        
        # _get_x_headers is not defined in the provided context, assuming it's a placeholder or will be added.
        # For now, we'll construct headers directly as per original logic, but keep the line if it's meant to be there.
        # headers = SocialVerificationService._get_x_headers() 
        
        bearer_token = await SocialVerificationService.get_config_value(db, "X_BEARER_TOKEN", "x_bearer_token")
        community_username = await SocialVerificationService.get_config_value(db, "X_COMMUNITY_USERNAME", "x_community_username")
        


        if not bearer_token or not community_username:
            logger.warning("X verification skipped: Missing config (Bearer Token or Community Username)")
            return True # Soft fail (assume success if not configured, or could be False depending on strictness)
        
        bearer_token = bearer_token.strip()
        community_username = community_username.strip().replace("@", "")

        # If community_username is a numeric ID (Community ID), we cannot verify membership via API v2.
        # We auto-verify (Trust Mode) to allow users to proceed.
        if community_username.isdigit():
            logger.info(f"X Verification: Community ID '{community_username}' detected. Auto-verifying (API does not support membership check).")
            return True

        # FIX: verification_data IS the username_or_id
        user_handle = verification_data.strip().replace("@", "")

        headers = {
            "Authorization": f"Bearer {bearer_token}",
            "Content-Type": "application/json"
        }

        async with httpx.AsyncClient() as client:
            try:
                # 1. Resolve Applicant ID
                user_lookup_url = f"https://api.twitter.com/2/users/by/username/{user_handle}"
                applicant_resp = await client.get(user_lookup_url, headers=headers)
                
                if applicant_resp.status_code != 200:
                    logger.error(f"X API Error (Applicant Lookup): {applicant_resp.text}")
                    return False
                
                applicant_data = applicant_resp.json()
                if "data" not in applicant_data:
                    return False 
                
                applicant_id = applicant_data["data"]["id"]

                # 2. Get Community ID (Target User)
                community_lookup_url = f"https://api.twitter.com/2/users/by/username/{community_username}"
                comm_resp = await client.get(community_lookup_url, headers=headers)
                
                if comm_resp.status_code != 200:
                     logger.error(f"X API Error (Community Lookup): {comm_resp.text}")
                     return True 
                
                comm_data = comm_resp.json()
                if "data" not in comm_data:
                     return True
                
                community_id = comm_data["data"]["id"]

                # 3. Check Exact Following (User Following Target)
                # Endpoint: POST /2/users/:id/following (No, ensure checking GET /2/users/:id/following)
                # We check if Applicant follows Community.
                
                # Optimized: Check relationship? /2/users/:id/following is standard.
                # However, checking if A follows B without iterating A's entire list is hard/expensive in V2 App Auth.
                # Tweepy uses get_users_following.
                
                # Let's stick to the list check for now but optimized to 5 pages (5000 users) if needed?
                # Or Use /2/users?ids=community_id&user.fields=connection_status provided valid User Context...
                # App Auth has limits.
                
                following_url = f"https://api.twitter.com/2/users/{applicant_id}/following"
                params = {"max_results": 1000} 
                
                has_next = True
                page_token = None
                pages_checked = 0
                max_pages = 2 
                
                while has_next and pages_checked < max_pages:
                    if page_token:
                        params["pagination_token"] = page_token
                    
                    resp = await client.get(following_url, headers=headers, params=params)
                    
                    if resp.status_code == 429:
                        logger.warning("X API Rate Limit Exceeded.")
                        return False 

                    if resp.status_code != 200:
                        logger.error(f"X API Error (Following Check): {resp.text}")
                        return False
                    
                    data = resp.json()
                    users = data.get("data", [])
                    
                    for u in users:
                        if u["id"] == community_id:
                            return True
                    
                    if "meta" in data and "next_token" in data["meta"]:
                        page_token = data["meta"]["next_token"]
                    else:
                        has_next = False
                    
                    pages_checked += 1
                
                return False

            except Exception as e:
                logger.error(f"X Verification Exception: {e}")
                return False

    @staticmethod
    async def verify_x_retweet(verification_data: str, tweet_url_or_id: str, db: AsyncSession, env: str = "release") -> bool:
        """
        Verifies if a user has retweeted a specific tweet via User Timeline check.
        """
        
        bearer_token = await SocialVerificationService.get_config_value(db, "X_BEARER_TOKEN", "x_bearer_token")
        
        if not bearer_token:
            logger.warning("X verification skipped: Missing Bearer Token")
            return True 
            
        bearer_token = bearer_token.strip()
        user_handle = verification_data.strip().replace("@", "")
        
        # Extract Tweet ID
        tweet_id = tweet_url_or_id
        if "status/" in tweet_id:
            try:
                tweet_id = tweet_id.split("status/")[1].split("?")[0].split("/")[0]
            except Exception:
                logger.error(f"Could not extract Tweet ID from: {tweet_url_or_id}")
                return False

        if not tweet_id.isdigit():
             logger.error(f"Invalid Tweet ID: {tweet_id}")
             return False

        headers = {
            "Authorization": f"Bearer {bearer_token}",
            "Content-Type": "application/json"
        }

        async with httpx.AsyncClient() as client:
            try:
                # 1. Resolve Applicant User ID
                user_lookup_url = f"https://api.twitter.com/2/users/by/username/{user_handle}"
                applicant_resp = await client.get(user_lookup_url, headers=headers)
                
                if applicant_resp.status_code != 200:
                    logger.error(f"X API Error (User Lookup): {applicant_resp.text}")
                    return False
                
                applicant_data = applicant_resp.json()
                if "data" not in applicant_data:
                    return False
                
                applicant_id = applicant_data["data"]["id"]

                # 2. Check User's Timeline for Retweet
                # Endpoint: GET /2/users/:id/tweets
                # Params: max_results=50, exclude=replies
                # Expansion: referenced_tweets.id
                
                timeline_url = f"https://api.twitter.com/2/users/{applicant_id}/tweets"
                params = {
                    "max_results": 100, 
                    "exclude": "replies",
                    "tweet.fields": "referenced_tweets"
                }
                
                # Check recent 100 tweets (should be enough for a recent mission)
                resp = await client.get(timeline_url, headers=headers, params=params)
                
                if resp.status_code != 200:
                     logger.error(f"X API Error (Timeline Check): {resp.text}")
                     return False
                
                data = resp.json()
                tweets = data.get("data", [])
                
                for t in tweets:
                    refs = t.get("referenced_tweets", [])
                    for ref in refs:
                        # Check if it is a 'retweeted' reference to our target ID
                        if ref["type"] == "retweeted" and ref["id"] == tweet_id:
                            return True
                            
                return False

            except Exception as e:
                logger.error(f"X Retweet Verification Exception: {e}")
                return False
