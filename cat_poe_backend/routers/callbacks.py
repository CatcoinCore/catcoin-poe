from fastapi import APIRouter, Request, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from datetime import datetime
import models, database
import logging
from services.admob_ssv import AdMobSSVService

router = APIRouter(
    prefix="/api/v1/callbacks",
    tags=["callbacks"],
)

logger = logging.getLogger(__name__)

@router.get("/admob-ssv")
async def admob_ssv_callback(request: Request, db: AsyncSession = Depends(database.get_db)):
    """
    Handle AdMob Server-Side Verification callbacks
    """
    # Get raw query string bytes and decode to ensure exact order/format matches
    # request.url.query might be normalized, checking raw scope is safer for signature verification
    logger.debug("SSV Callback Received: %s %s", request.method, request.url)
    
    # Get raw query string bytes and decode to ensure exact order/format matches
    raw_query = request.scope['query_string'].decode('utf-8') if request.scope.get('query_string') else ""
    
    # Fallback to request.url.query if raw_query is empty but url.query exists (unlikely in Standard ASGI but good for safety)
    if not raw_query and request.url.query:
        logger.warning("Scope query string empty, using request.url.query")
        raw_query = request.url.query

    logger.debug("Processing SSV Query: %s", raw_query)

    # Verify Signature
    is_valid = await AdMobSSVService.verify_signature(raw_query)
    if not is_valid:
        # Log failure with the exact string we tried to verify
        logger.warning(f"AdMob SSV Verification Failed. Query: {raw_query}")
        raise HTTPException(status_code=400, detail="Invalid signature")

    # Extract Params
    params = dict(request.query_params)
    transaction_id = params.get('transaction_id')
    user_id_str = params.get('user_id') or params.get('custom_data') # support both
    
    if not transaction_id or not user_id_str:
        # Allow Google Test Transaction ID to pass without user_id (common in generic test ads)
        if transaction_id == "123456789":
             logger.warning(f"Test Ad Transaction {transaction_id} received without user_id. proceeding for testing purposes.")
             # Use a dummy user ID for testing or fail gracefully?
             # If we proceed, we need a user to credit. 
             # We can't credit a specific user if ID is missing.
             # So we just returns OK to satisfy the callback test.
             return {"status": "ok", "message": "Test Ad Processed (No User Linked)"}

        logger.warning("Missing transaction_id or user_id")
        raise HTTPException(status_code=400, detail="Missing parameters")

    # Check for Duplicate Transaction
    result = await db.execute(select(models.AdView).where(models.AdView.transaction_id == transaction_id))
    existing = result.scalars().first()
    if existing:
        logger.info(f"Duplicate AdMob Transaction: {transaction_id}")
        return {"status": "ok", "message": "Already processed"}

    # Verify User Exists
    try:
        user_uuid = user_id_str # UUID conversion handled by DB or validation
        import uuid
        user_uuid_obj = uuid.UUID(user_uuid)
    except ValueError:
        logger.error(f"Invalid User UUID: {user_id_str}")
        # Can't credit unknown user.
        return {"status": "error", "message": "Invalid User ID"}

    # Determine Timestamp
    ts_val = params.get('timestamp') # Epoch ID
    # AdMob timestamp is in milliseconds? Or simple ID? 
    # Docs: "timestamp: Timestamp of the reward event."
    # Usually milliseconds.
    try:
        if ts_val:
            ad_timestamp = datetime.utcfromtimestamp(int(ts_val) / 1000.0)
        else:
            ad_timestamp = datetime.utcnow()
    except:
        ad_timestamp = datetime.utcnow()

    # Store Ad View
    new_view = models.AdView(
        transaction_id=transaction_id,
        user_id=user_uuid_obj,
        timestamp=ad_timestamp,
        verified=True,
        used_at=None # Available for use
    )
    db.add(new_view)
    await db.commit()
    
    logger.info(f"AdMob Reward Verified: User {user_uuid} - Tx {transaction_id}")
    return {"status": "ok"}
