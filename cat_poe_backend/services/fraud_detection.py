import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, or_
import models
from services.social_lock_service import normalize_social_value


class FraudDetectionService:
    @staticmethod
    def should_log_social_profile_change(
        *,
        old_norm: str | None,
        new_norm: str | None,
        verified_change: bool,
    ) -> bool:
        """
        First-time set (null/empty -> non-empty) is normal onboarding and must not be flagged.

        `old_norm` / `new_norm` must already be passed through `normalize_social_value` so that
        harmless differences (@, case, whitespace) do not create false positives.

        Verified-ID swaps still log when the canonical handle actually changes.
        """
        if verified_change:
            return bool(old_norm != new_norm)
        if not new_norm:
            return False
        if not old_norm:
            return False
        return old_norm != new_norm

    @staticmethod
    async def log_suspicious_activity(
        db: AsyncSession, 
        user_id: uuid.UUID, 
        activity_type: str, 
        evidence: str,
        related_user_id: uuid.UUID = None
    ):
        """
        Log a suspicious event and mark user as suspicious.
        """
        # Check for existing duplicate *unresolved* log to prevent spam while still
        # allowing a fresh flag after an admin resolved a prior identical-looking row.
        query = select(models.SuspiciousActivity).where(
            models.SuspiciousActivity.user_id == user_id,
            models.SuspiciousActivity.activity_type == activity_type,
            models.SuspiciousActivity.evidence == evidence,
            models.SuspiciousActivity.related_user_id == related_user_id,
            models.SuspiciousActivity.is_resolved == False,
        )
        result = await db.execute(query)
        if result.scalars().first():
            return

        # Create log entry
        activity = models.SuspiciousActivity(
            user_id=user_id,
            activity_type=activity_type,
            evidence=evidence,
            related_user_id=related_user_id
        )
        db.add(activity)
        
        # Mark user as suspicious
        # We need to fetch the user first to update or use update statement
        result = await db.execute(select(models.User).where(models.User.id == user_id))
        user = result.scalars().first()
        if user and not user.is_suspicious:
            user.is_suspicious = True
        
        # We do NOT commit here, we let the caller commit to ensure atomicity with the main operation
        # But if the caller acts on "suspicious" flag immediately, they might need flush
        await db.flush()

    @staticmethod
    async def check_suspicious_activity(
        db: AsyncSession, 
        user: models.User, 
        ip_address: str, 
        device_id: str
    ):
        """
        Check for multi-account usage based on IP and Device ID.
        Triggered during Signup and Login (?). Currently planned for Signup.
        If triggered, logs activity.
        """
        if device_id in ("null", "None", "", "N/A", "undefined"):
            device_id = None
        if ip_address in ("null", "None", "", "N/A", "undefined", "127.0.0.1", "172.18.0.4"):
            ip_address = None
            
        if not device_id and not ip_address:
            return

        # 1. Device ID Check (Strong Signal)
        # Check if any OTHER user has this device_id
        if device_id:
            query = select(models.User).where(
                models.User.device_id == device_id,
                models.User.id != user.id
            ).limit(1)
            result = await db.execute(query)
            existing_user = result.scalars().first()
            
            if existing_user:
                await FraudDetectionService.log_suspicious_activity(
                    db, 
                    user.id, 
                    "MULTIPLE_ACCOUNTS_DEVICE", 
                    f"Device ID ({device_id}) used by another user",
                    related_user_id=existing_user.id
                )

        # 2. IP Address Check (Weak Signal - Higher Threshold)
        # Check count of users with this IP
        if ip_address:
            query = select(func.count(models.User.id)).where(
                models.User.ip_address == ip_address
            )
            result = await db.execute(query)
            count = result.scalar()
            
            # If this is a new signup, they are already inserted or about to be inserted?
            # If passed 'user' object is already in DB, count includes them.
            # Threshold: > 3 accounts
            if count > 3:
                # Find one related user for evidence
                sub_query = select(models.User).where(
                    models.User.ip_address == ip_address,
                    models.User.id != user.id
                ).limit(1)
                res = await db.execute(sub_query)
                related = res.scalars().first()
                
                await FraudDetectionService.log_suspicious_activity(
                    db, 
                    user.id, 
                    "IP_FARMING", 
                    f"IP address ({ip_address}) used by {count} accounts",
                    related_user_id=related.id if related else None
                )

    @staticmethod
    async def check_duplicate_socials(
        db: AsyncSession,
        user_id: uuid.UUID,
        discord_id: str = None,
        telegram_id: str = None,
        x_id: str = None
    ):
        """
        Check if Social IDs are already in use.
        """
        checks = [
            ("discord_id", discord_id, "DUPLICATE_DISCORD"),
            ("telegram_id", telegram_id, "DUPLICATE_TELEGRAM"),
            ("x_id", x_id, "DUPLICATE_X"),
        ]
        
        for field, value, type_code in checks:
            norm = normalize_social_value(value)
            if norm:
                query = select(models.User).where(
                    getattr(models.User, field) == norm,
                    models.User.id != user_id
                ).limit(1)
                result = await db.execute(query)
                existing = result.scalars().first()

                if existing:
                    await FraudDetectionService.log_suspicious_activity(
                        db,
                        user_id,
                        type_code,
                        f"Duplicate {field}: {norm}",
                        related_user_id=existing.id
                    )

    @staticmethod
    async def check_duplicate_wallet(
        db: AsyncSession,
        user_id: uuid.UUID,
        wallet_address: str
    ):
        """
        Check if Wallet Address is already in use.
        """
        query = select(models.Wallet).join(models.User).where(
            models.Wallet.catcoin_address == wallet_address,
            models.Wallet.user_id != user_id
        ).limit(1)
        
        result = await db.execute(query)
        existing_wallet = result.scalars().first()
        
        if existing_wallet:
            await FraudDetectionService.log_suspicious_activity(
                db,
                user_id,
                "DUPLICATE_WALLET",
                f"Wallet address used by another user",
                related_user_id=existing_wallet.user_id
            )
