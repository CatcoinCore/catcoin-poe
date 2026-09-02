import logging
import os
import requests
from requests_oauthlib import OAuth1
from services.session_manager import SessionManager
from services.secret_crypto import decrypt_if_encrypted, SENSITIVE_ADMIN_CONFIG_FIELDS
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)

class XService:
    @staticmethod
    async def get_config_value(db: AsyncSession, key_env: str, key_db_attr: str) -> str:
        # DB first, then Env? Or Env first (overrides)?
        # SocialVerificationService does Env first. Let's stick to that consistency.
        # But user wants to update easier -> implies DB should take precedence or at least be the primary way if set.
        # IF user sets it in Admin Panel, they expect it to work.
        # IF env is set, it might block DB value if we check Env first.
        # However, for security, Env is usually preferred. 
        # But convenient updates = DB.
        # Let's do: Check Env. If empty, check DB.
        # Wait, if I want to override Env with DB, I should check DB first?
        # Standard: Env overrides config files/DB.
        # Let's stick to Env first. User can empty Env if they want DB to manage it.
        
        val = os.getenv(key_env)
        if val: return val

        try:
            config = await SessionManager.get_admin_config(db)
            db_val = getattr(config, key_db_attr, None)
            if db_val and key_db_attr in SENSITIVE_ADMIN_CONFIG_FIELDS:
                db_val = decrypt_if_encrypted(db_val)
            return db_val
        except Exception as e:
            logger.error(f"Error fetching DB config for {key_db_attr}: {e}")
            return None

    @staticmethod
    async def post_tweet(text: str, db: AsyncSession) -> dict:
        """
        Posts a tweet using OAuth 1.0a User Context.
        Returns the response JSON or raises Exception.
        """
        consumer_key = await XService.get_config_value(db, "X_CONSUMER_KEY", "x_consumer_key")
        consumer_secret = await XService.get_config_value(db, "X_CONSUMER_SECRET", "x_consumer_secret")
        access_token = await XService.get_config_value(db, "X_ACCESS_TOKEN", "x_access_token")
        access_token_secret = await XService.get_config_value(db, "X_ACCESS_TOKEN_SECRET", "x_access_token_secret")

        if not all([consumer_key, consumer_secret, access_token, access_token_secret]):
            logger.error("X API Credentials missing (Env or DB).")
            raise ValueError("X API Credentials not configured.")

        url = "https://api.twitter.com/2/tweets"
        auth = OAuth1(consumer_key, consumer_secret, access_token, access_token_secret)
        
        payload = {"text": text}

        # Check for Community ID
        community_username = await XService.get_config_value(db, "X_COMMUNITY_USERNAME", "x_community_username")
        if community_username:
            community_username = community_username.strip()
            if community_username.isdigit():
                payload["community_id"] = community_username
                logger.info(f"Targeting Community ID: {community_username}")
        
        try:
            # We are in async method but using synchronous requests? 
            # Requests is blocking. We should use httpx + oauthlib or run in executor.
            # But duplicate logic from SocialVerificationService uses httpx.
            # requests_oauthlib with httpx is tricky.
            # Simplest for now: Run blocking requests in threadpool or just block (it's one admin action).
            # Admin action = low traffic. Blocking is acceptable for "post tweet" feature.
            # Better: use asyncio.to_thread
            import asyncio
            
            def _do_post():
                return requests.post(url, json=payload, auth=auth, timeout=10)
            
            response = await asyncio.to_thread(_do_post)
            
            if response.status_code == 201:
                data = response.json()
                logger.info(f"Tweet posted successfully: {data.get('data', {}).get('id')}")
                return data
            else:
                logger.error(f"Failed to post tweet: {response.status_code} - {response.text}")
                raise Exception(f"X API Error: {response.text}")
                
        except Exception as e:
            logger.error(f"Exception posting tweet: {e}")
            raise e
