from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import database
import auth
import models

router = APIRouter(prefix="/admin/config", tags=["admin"])

@router.post("/reset-extension-slots")
async def reset_extension_slots(
    _: models.User = Depends(auth.require_admin),
    db: AsyncSession = Depends(database.get_db),
):
    """Reset time_extension_slots to support 2-6 hour extensions"""
    await db.execute(
        text("UPDATE admin_config SET time_extension_slots = '[120, 180, 240, 300, 360]' WHERE id = 1")
    )
    await db.commit()
    return {"message": "Extension slots updated to support 2h, 3h, 4h, 5h, 6h extensions"}
