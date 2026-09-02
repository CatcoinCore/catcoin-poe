from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import models, schemas, database, auth
import uuid
from services.fraud_detection import FraudDetectionService

router = APIRouter(
    tags=["wallets"],
)

@router.post("/wallets", response_model=schemas.WalletResponse)
async def add_wallet(
    wallet: schemas.WalletCreate,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    user_id = user.id  # Capture before async operations
    
    # Check for Duplicate Wallet (Fraud Detection)
    await FraudDetectionService.check_duplicate_wallet(db, user_id, wallet.catcoin_address)

    # Map string source to Enum
    source_enum = models.WalletSource.MANUAL
    if wallet.source:
        try:
            source_enum = models.WalletSource(wallet.source)
        except ValueError:
            pass # Default to MANUAL if invalid

    db_wallet = models.Wallet(**wallet.dict(exclude={'source'}), source=source_enum, user_id=user_id)
    db.add(db_wallet)
    await db.commit()
    await db.refresh(db_wallet)
    return db_wallet

@router.get("/wallets", response_model=List[schemas.WalletResponse])
async def get_wallets(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    user_id = user.id  # Capture before async operations
    result = await db.execute(select(models.Wallet).where(models.Wallet.user_id == user_id))
    return result.scalars().all()

@router.delete("/wallets/{wallet_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_wallet(
    wallet_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    user_id = user.id
    try:
        wallet_uuid = uuid.UUID(wallet_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid wallet ID format")

    result = await db.execute(
        select(models.Wallet)
        .where(models.Wallet.id == wallet_uuid)
        .where(models.Wallet.user_id == user_id)
    )
    wallet = result.scalars().first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")
    
    await db.delete(wallet)
    await db.commit()
    return None

@router.put("/wallets/{wallet_id}/primary", response_model=schemas.WalletResponse)
async def set_primary_wallet(
    wallet_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    user_id = user.id
    try:
        wallet_uuid = uuid.UUID(wallet_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid wallet ID format")

    # Verify wallet exists and belongs to user
    result = await db.execute(
        select(models.Wallet)
        .where(models.Wallet.id == wallet_uuid)
        .where(models.Wallet.user_id == user_id)
    )
    target_wallet = result.scalars().first()
    if not target_wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")

    # Unset is_primary for all user's wallets
    # Using execute with update is more efficient but requires care with async session
    # Simpler approach for now: fetch all and iterate (assuming few wallets)
    # Better approach:
    await db.execute(
        models.Wallet.__table__.update()
        .where(models.Wallet.user_id == user_id)
        .values(is_primary=False)
    )

    # Set target as primary
    target_wallet.is_primary = True
    db.add(target_wallet) # Re-add to session just in case
    
    await db.commit()
    await db.refresh(target_wallet)
    return target_wallet

@router.post("/wallets/verify/{wallet_id}")
async def verify_wallet(
    wallet_id: str,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Mock wallet verification"""
    # Capture attributes upfront to avoid missing greenlet
    user_id = user.id 
    
    try:
        wallet_uuid = uuid.UUID(wallet_id)
    except ValueError:
         raise HTTPException(status_code=400, detail="Invalid wallet ID format")

    result = await db.execute(
        select(models.Wallet)
        .where(models.Wallet.id == wallet_uuid)
        .where(models.Wallet.user_id == user_id)
    )
    wallet = result.scalars().first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")
    
    # Mock verification - in real app would verify blockchain signature
    return {"message": "Wallet verified", "wallet_id": str(wallet.id)}
