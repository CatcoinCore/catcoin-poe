import httpx
import base64
import logging
from urllib.parse import parse_qsl, unquote
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.backends import default_backend
from cryptography.exceptions import InvalidSignature
from datetime import datetime

ADMOB_KEYS_URL = "https://www.gstatic.com/admob/reward/verifier-keys.json"

logger = logging.getLogger(__name__)

class AdMobSSVService:
    _keys_cache = {}
    _last_fetch = None

    @classmethod
    async def get_public_keys(cls):
        """Fetch Google's public keys for AdMob SSV (Cached)"""
        now = datetime.utcnow()
        if cls._keys_cache and cls._last_fetch and (now - cls._last_fetch).total_seconds() < 86400: # 24h cache
            return cls._keys_cache
        
        try:
            async with httpx.AsyncClient(follow_redirects=True) as client:
                resp = await client.get(ADMOB_KEYS_URL)
                resp.raise_for_status()
                data = resp.json()
                
                new_keys = {}
                for key in data.get('keys', []):
                    new_keys[str(key['keyId'])] = key['pem']
                
                cls._keys_cache = new_keys
                cls._last_fetch = now
                logger.info(f"Refreshed AdMob public keys: {list(new_keys.keys())}")
                return new_keys
        except Exception as e:
            logger.error(f"Error fetching AdMob keys: {e}")
            return cls._keys_cache or {}

    @classmethod
    async def verify_signature(cls, query_string: str) -> bool:
        """
        Verify AdMob SSV signature
        query_string: The raw query string from the callback URL (e.g. "ad_network=...&signature=...")
        """
        params = dict(parse_qsl(query_string, keep_blank_values=True))
        
        signature = params.get('signature')
        key_id = params.get('key_id')
        
        if not signature or not key_id:
            logger.warning("AdMob SSV Verification failed: Missing signature or key_id")
            return False
            
        # Reconstruct message: Query string WITHOUT signature param
        # We must preserve the exact order and content of other params including key_id
        param_list = query_string.split('&')
        msg_params = [p for p in param_list if not p.startswith('signature=')]
        message = '&'.join(msg_params)
        
        keys = await cls.get_public_keys()
        pem_key = keys.get(str(key_id))
        
        if not pem_key:
            logger.warning(f"AdMob SSV Verification failed: Key ID {key_id} not found in {list(keys.keys())}")
            # Force refresh keys if key not found?
            # For now, just fail.
            return False
            
        try:
            # Decode signature
            # Try URL-safe first, then standard (in case it was unquoted strange)
            sig_bytes = None
            padded_signature = signature + '=' * (-len(signature) % 4)
            
            try:
                sig_bytes = base64.urlsafe_b64decode(padded_signature)
            except Exception:
                try:
                    sig_bytes = base64.b64decode(padded_signature)
                except Exception as e:
                    logger.error(f"Failed to decode signature: {signature} - {e}")
                    return False

            # Load Public Key
            public_key = serialization.load_pem_public_key(
                pem_key.encode('utf-8'),
                backend=default_backend()
            )
            
            # Helper to try validation
            def try_verify(msg_bytes):
                 public_key.verify(
                    sig_bytes,
                    msg_bytes,
                    ec.ECDSA(hashes.SHA256())
                )
            
            # Try 1: As received (minus signature)
            try:
                try_verify(message.encode('utf-8'))
                logger.info(f"AdMob SSV Signature Verified (Unsorted) for key {key_id}")
                return True
            except InvalidSignature:
                pass
            
            # Try 2: Sorted parameters (AdMob standard)
            # Reconstruct by parsing, sorting keys, and joining
            try:
                # 1. Split into key-value pairs
                pairs = []
                for p in param_list:
                    if p.startswith('signature='):
                        continue
                    if '=' in p:
                        k, v = p.split('=', 1)
                        pairs.append((k, v))
                    else:
                        pairs.append((p, ''))
                
                # 2. Sort by key
                pairs.sort(key=lambda x: x[0])
                
                # 3. Join back
                message_sorted = '&'.join([f"{k}={v}" if v else k for k, v in pairs])
                
                try_verify(message_sorted.encode('utf-8'))
                logger.info(f"AdMob SSV Signature Verified (Sorted) for key {key_id}")
                return True
            except InvalidSignature:
                pass

            # Try 3: Exclude key_id (Hypothesis: signature covers only payload params)
            try:
                # Remove key_id from UNSORTED message
                params_no_key = [p for p in param_list if not p.startswith('signature=') and not p.startswith('key_id=')]
                message_no_key = '&'.join(params_no_key)
                
                try_verify(message_no_key.encode('utf-8'))
                logger.info(f"AdMob SSV Signature Verified (No KeyID) for key {key_id}")
                return True
            except InvalidSignature:
                logger.warning(f"AdMob SSV Invalid Signature (All Methods). Unsorted: {message} | Sorted: {message_sorted} | NoKey: {message_no_key}")
                return False
            
        except InvalidSignature:
            logger.warning(f"AdMob SSV Invalid Signature. Message: {message} | Signature: {signature}")
            return False
        except Exception as e:
            logger.error(f"AdMob SSV Verification Error: {e}")
            return False
