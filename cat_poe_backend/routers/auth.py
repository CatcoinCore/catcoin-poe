import uuid
import secrets
from typing import List, Optional
from datetime import timedelta, datetime
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, or_
import models, schemas, database, auth
from config import settings
from services import auth_messages
from services.auth_rate_limit import client_ip_from_request, enforce_rate_limit
from services.social_lock_service import (
    SOCIAL_FIELD_PREFIXES,
    normalize_social_value,
    revoke_platform_mission_rewards,
    write_audit,
)

SOCIAL_CHANGE_CONFIRM_ERROR = "SOCIAL_ID_CHANGE_REQUIRES_CONFIRMATION"
from services.session_manager import SessionManager
from services.email_service import EmailService
from services.fraud_detection import FraudDetectionService
from services.referral_signup_bonus import grant_referral_signup_bonuses
from services.referral_assignment import (
    REFERRAL_ERR_REFERRER_NOT_FOUND,
    can_set_referred_by,
    log_referral_audit,
)
from services.referral_observability import log_referral_milestone
from utils.user_utils import generate_unique_username, generate_verification_code
from fastapi import Request

router = APIRouter(
    prefix="/auth",
    tags=["auth"],
)


def _signup_ip_and_device(request: Request) -> tuple[Optional[str], Optional[str]]:
    cf_ip = request.headers.get("CF-Connecting-IP")
    if cf_ip:
        ip_address = cf_ip.split(",")[0].strip()
    else:
        x_forwarded_for = request.headers.get("X-Forwarded-For")
        if x_forwarded_for:
            ip_address = x_forwarded_for.split(",")[0].strip()
        else:
            ip_address = request.headers.get(
                "X-Real-IP", request.client.host if request.client else None
            )
    device_id = request.headers.get("X-Device-ID")
    if ip_address in ("null", "None", "", "N/A", "127.0.0.1", "172.18.0.4"):
        ip_address = None
    return ip_address, device_id


@router.post("/signup", response_model=schemas.SignupAckResponse)
async def signup(
    user: schemas.UserCreate,
    request: Request,
    db: AsyncSession = Depends(database.get_db),
):
    """
    Register new user with email
    - Auto-generates 9-digit username (900000000-999999999)
    - Sends verification email with 6-digit code
    - User must verify email before full access
    - If the email exists but is not verified yet: updates password, sends a new code,
      returns SIGNUP_EXISTING_UNVERIFIED_ACK (distinct message).
    - If the email exists and is verified: same generic SIGNUP_ACK as unknown emails (enumeration-resistant).
    """
    ip = client_ip_from_request(request)
    await enforce_rate_limit(
        f"signup:ip:{ip}", settings.AUTH_RL_SIGNUP_PER_HOUR_IP, 3600.0
    )

    result = await db.execute(select(models.User).where(models.User.email == user.email))
    existing_user = result.scalars().first()
    if existing_user:
        if existing_user.email_verified:
            return {"message": auth_messages.SIGNUP_ACK}

        ip_address, device_id = _signup_ip_and_device(request)
        verification_code = generate_verification_code()
        verification_expires = EmailService.get_verification_expiry()

        existing_user.hashed_password = auth.get_password_hash(user.password)
        existing_user.verification_code = verification_code
        existing_user.verification_code_expires = verification_expires
        existing_user.password_reset_code = None
        existing_user.password_reset_expires = None
        existing_user.ip_address = ip_address
        existing_user.device_id = device_id

        await db.flush()
        await db.refresh(existing_user)
        await FraudDetectionService.check_suspicious_activity(
            db, existing_user, ip_address, device_id
        )

        await db.commit()
        await db.refresh(existing_user)

        sent = await EmailService.send_verification_email(
            user.email, verification_code, existing_user.username
        )
        if not sent:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=auth_messages.EMAIL_DELIVERY_UNAVAILABLE,
            )

        return {"message": auth_messages.SIGNUP_EXISTING_UNVERIFIED_ACK}

    # Generate unique 9-digit username
    username = await generate_unique_username(db)
    
    # Generate verification code
    verification_code = generate_verification_code()
    verification_expires = EmailService.get_verification_expiry()
    
    # Generate referral code
    referral_code = str(uuid.uuid4())[:8]

    ip_address, device_id = _signup_ip_and_device(request)

    rb_raw = (user.referred_by or "").strip()
    referrer_for_row: Optional[models.User] = None
    if rb_raw:
        r = await db.execute(
            select(models.User).where(
                func.lower(models.User.referral_code) == rb_raw.lower()
            )
        )
        referrer_for_row = r.scalars().first()
        if not referrer_for_row:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "error_code": REFERRAL_ERR_REFERRER_NOT_FOUND,
                    "message": "Invalid or unknown referral code",
                },
            )

    # Create user
    hashed_password = auth.get_password_hash(user.password)
    db_user = models.User(
        username=username,
        email=user.email,
        display_name=None,  # User can set this later
        hashed_password=hashed_password,
        referral_code=referral_code,
        referred_by=rb_raw.lower() if rb_raw else None,
        email_verified=False,
        verification_code=verification_code,
        verification_code_expires=verification_expires,
        ip_address=ip_address,
        device_id=device_id
    )
    db.add(db_user)
    
    # Run Fraud Detection (After adding to session but before commit? need ID? Yes need ID)
    # So we flush first to get ID
    await db.flush()
    await db.refresh(db_user)

    if rb_raw and referrer_for_row:
        ok, err_detail = await can_set_referred_by(
            db,
            db_user,
            referrer=referrer_for_row,
            proposed_code_lower=rb_raw.lower(),
        )
        if not ok:
            await db.rollback()
            ec = (
                err_detail.get("error_code")
                if isinstance(err_detail, dict)
                else None
            )
            log_referral_milestone(
                "referral_assignment_rejected",
                trigger="signup",
                referee_user_id=str(db_user.id),
                referrer_user_id=str(referrer_for_row.id),
                error_code=ec,
            )
            log_referral_audit(
                "signup_referred_by_blocked",
                email=user.email,
                detail=err_detail,
            )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=err_detail,
            )
        from services.referral_bonus import ensure_referral_row

        row = await ensure_referral_row(
            db, referrer_for_row, db_user, trigger="signup"
        )
        if row:
            log_referral_audit(
                "signup_referral_row_created",
                referee_id=str(db_user.id),
                referrer_id=str(referrer_for_row.id),
            )

    await FraudDetectionService.check_suspicious_activity(db, db_user, ip_address, device_id)

    await db.commit()
    await db.refresh(db_user)

    # Send verification email
    sent = await EmailService.send_verification_email(
        user.email, verification_code, username
    )
    if not sent:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=auth_messages.EMAIL_DELIVERY_UNAVAILABLE,
        )

    return {"message": auth_messages.SIGNUP_ACK}

@router.post("/verify-email", response_model=schemas.Token)
async def verify_email(
    http_request: Request,
    payload: schemas.VerifyEmailRequest,
    db: AsyncSession = Depends(database.get_db),
):
    """
    Verify email with 6-digit code
    - Checks code validity and expiration
    - Auto-login after successful verification
    """
    ip = client_ip_from_request(http_request)
    await enforce_rate_limit(
        f"verify:ip:{ip}", settings.AUTH_RL_VERIFY_PER_MINUTE_IP, 60.0
    )

    result = await db.execute(
        select(models.User).where(models.User.email == payload.email)
    )
    user = result.scalars().first()

    if not user or user.email_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=auth_messages.INVALID_VERIFICATION_CODE,
        )

    vc = user.verification_code
    if (
        not vc
        or not payload.code
        or not secrets.compare_digest(vc, payload.code)
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=auth_messages.INVALID_VERIFICATION_CODE,
        )

    if (
        not user.verification_code_expires
        or datetime.utcnow() > user.verification_code_expires
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=auth_messages.INVALID_VERIFICATION_CODE,
        )

    # Mark as verified
    user.email_verified = True
    user.verification_code = None
    user.verification_code_expires = None
    user.password_reset_code = None
    user.password_reset_expires = None

    await grant_referral_signup_bonuses(db, user)

    # Store attributes BEFORE commit to avoid lazy access issues
    username = user.username
    user_id = user.id

    await db.commit()
    
    # Auto-login: create tokens
    access_token_expires = timedelta(minutes=auth.settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": username}, expires_delta=access_token_expires
    )
    refresh_token = await auth.create_refresh_token(user_id, db, device_info="mobile_app")
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }

@router.post("/resend-code")
async def resend_verification_code(
    http_request: Request,
    payload: schemas.ResendCodeRequest,
    db: AsyncSession = Depends(database.get_db),
):
    """Resend verification code to email"""
    ip = client_ip_from_request(http_request)
    email_key = str(payload.email).strip().lower()
    await enforce_rate_limit(
        f"resend:ip:{ip}", settings.AUTH_RL_RESEND_PER_HOUR_IP, 3600.0
    )
    await enforce_rate_limit(
        f"resend:email:{email_key}",
        settings.AUTH_RL_RESEND_PER_HOUR_EMAIL,
        3600.0,
    )

    result = await db.execute(
        select(models.User).where(models.User.email == payload.email)
    )
    user = result.scalars().first()

    if not user or user.email_verified:
        return {"message": auth_messages.RESEND_VERIFICATION_ACK}

    # Generate new code
    verification_code = generate_verification_code()
    verification_expires = EmailService.get_verification_expiry()

    # Store attributes BEFORE commit to avoid lazy-loading issues
    user_email = user.email
    user_username = user.username

    user.verification_code = verification_code
    user.verification_code_expires = verification_expires
    user.password_reset_code = None
    user.password_reset_expires = None
    await db.commit()

    # Send email (using stored values)
    sent = await EmailService.send_verification_email(
        user_email, verification_code, user_username
    )
    if not sent:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=auth_messages.EMAIL_DELIVERY_UNAVAILABLE,
        )

    return {"message": auth_messages.RESEND_VERIFICATION_ACK}

@router.post("/login", response_model=schemas.Token)
async def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(), 
    db: AsyncSession = Depends(database.get_db)
):
    """
    Login with email OR username + password
    - Requires email to be verified
    - Completes expired sessions on login
    """
    ip = client_ip_from_request(request)
    await enforce_rate_limit(
        f"login:ip:{ip}", settings.AUTH_RL_LOGIN_PER_MINUTE_IP, 60.0
    )

    # Try to find user by username OR email
    result = await db.execute(
        select(models.User).where(
            or_(
                models.User.username == form_data.username,
                models.User.email == form_data.username
            )
        )
    )
    user = result.scalars().first()
    
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email/username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Check if email is verified
    if not user.email_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Email not verified. Please check your email for verification code.",
        )
        
    # Check if soft-deleted
    if user.is_deleted:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account deleted. You cannot login.",
        )
    
    # Store user attributes
    user_id = user.id
    username = user.username
    
    # Complete expired sessions and referral boosts for inactive referrals
    completed_sessions = await SessionManager.cleanup_user_mining_sessions(user_id, db)
    if completed_sessions:
        print(f"Login cleanup: Completed {len(completed_sessions)} expired sessions for user {username}")
    
    # Update latest connection info
    cf_ip = request.headers.get("CF-Connecting-IP")
    if cf_ip:
        ip_address = cf_ip.split(",")[0].strip()
    else:
        x_forwarded_for = request.headers.get("X-Forwarded-For")
        if x_forwarded_for:
            ip_address = x_forwarded_for.split(",")[0].strip()
        else:
            ip_address = request.headers.get("X-Real-IP", request.client.host if request.client else None)
            
    device_id = request.headers.get("X-Device-ID")

    if ip_address and ip_address not in ("null", "None", "", "N/A", "127.0.0.1", "172.18.0.4"):
        user.ip_address = ip_address
    if device_id and device_id not in ("null", "None", "", "N/A"):
        user.device_id = device_id

    await db.commit()
    
    # Create tokens
    access_token_expires = timedelta(minutes=auth.settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": username}, expires_delta=access_token_expires
    )
    refresh_token = await auth.create_refresh_token(user_id, db, device_info="mobile_app")
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }

@router.post("/refresh", response_model=schemas.Token)
async def refresh_token(
    body: schemas.RefreshTokenRequest,
    db: AsyncSession = Depends(database.get_db),
):
    """Exchange refresh token for new access + refresh tokens (rotating refresh)."""
    user, new_refresh = await auth.rotate_refresh_token(body.refresh_token, db)

    access_token_expires = timedelta(minutes=auth.settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.username},
        expires_delta=access_token_expires,
    )

    return {
        "access_token": access_token,
        "refresh_token": new_refresh,
        "token_type": "bearer",
    }

@router.post("/logout")
async def logout(
    request: schemas.RefreshTokenRequest,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Logout and revoke refresh token"""
    await auth.revoke_refresh_token(
        request.refresh_token, db, acting_user_id=user.id
    )
    return {"message": "Logged out successfully"}

@router.post("/delete-account-request")
async def delete_account_request(
    request: schemas.UserDeleteRequest,
    db: AsyncSession = Depends(database.get_db)
):
    """
    Public endpoint for account deletion requests
    - Verifies credentials
    - Hashes identity for fraud prevention
    - Anonymizes PII
    - Soft deletes account
    """
    # Find user
    result = await db.execute(select(models.User).where(models.User.email == request.email))
    user = result.scalars().first()
    
    if not user or not auth.verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
        
    if user.is_deleted:
        raise HTTPException(status_code=400, detail="Account already deleted")

    # Hash identity for anti-farming
    import hashlib
    email_hash = hashlib.sha256(user.email.encode('utf-8')).hexdigest()
    
    # Store hashed identity if not exists
    existing_hash = await db.execute(select(models.DeletedIdentity).where(models.DeletedIdentity.identity_hash == email_hash))
    if not existing_hash.scalars().first():
        db.add(models.DeletedIdentity(
            identity_hash=email_hash,
            total_rewards=user.balance  # Store current balance/rewards
        ))
    
    # Anonymize User Data
    # We append UUID to ensure uniqueness constraints are met but PII is gone
    anonymized_suffix = str(uuid.uuid4())[:8]
    user.username = f"deleted_{anonymized_suffix}"
    user.email = f"deleted_{anonymized_suffix}@void.catcoin"
    user.display_name = "Deleted User"
    user.is_deleted = True
    user.deleted_at = datetime.utcnow()
    
    # Clear Social IDs
    user.discord_id = None
    user.telegram_id = None
    user.x_id = None
    user.facebook_id = None
    user.whatsapp_id = None
    
    # Revoke tokens (same as delete_account)
    from sqlalchemy import update
    await db.execute(
        update(models.RefreshToken)
        .where(models.RefreshToken.user_id == user.id)
        .values(revoked=True)
    )
    
    await db.commit()
    return {"message": "Account deleted successfully"}

@router.get("/users/me", response_model=schemas.UserResponse)
async def get_current_user_info(
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Get current user profile with referrer info"""
    # Capture attributes upfront to avoid MissingGreenlet
    user_id = current_user.id
    referred_by_code = current_user.referred_by
    
    
    # Calculate Dynamic Balance from Ledger
    from services.session_manager import EarningsManager
    dynamic_balance = await EarningsManager.get_user_balance(user_id, db)

    # Build response dict from user
    response_data = {
        "id": user_id,
        "username": current_user.username,
        "email": current_user.email,
        "display_name": current_user.display_name,
        "referral_code": current_user.referral_code,
        "referred_by": referred_by_code,
        "referred_by_display_name": None,
        "balance": dynamic_balance, # Use dynamic balance
        "email_verified": current_user.email_verified,
        "created_at": current_user.created_at,
        "is_admin": current_user.is_admin,
        "discord_id": current_user.discord_id,
        "discord_id_verified": current_user.discord_id_verified,
        "discord_id_locked": getattr(current_user, "discord_id_locked", False) or False,
        "telegram_id": current_user.telegram_id,
        "telegram_id_verified": current_user.telegram_id_verified,
        "telegram_id_locked": getattr(current_user, "telegram_id_locked", False) or False,
        "x_id": current_user.x_id,
        "x_id_verified": current_user.x_id_verified,
        "x_id_locked": getattr(current_user, "x_id_locked", False) or False,
        "facebook_id": current_user.facebook_id,
        "facebook_id_verified": current_user.facebook_id_verified,
        "facebook_id_locked": getattr(current_user, "facebook_id_locked", False) or False,
        "whatsapp_id": current_user.whatsapp_id,
        "whatsapp_id_verified": current_user.whatsapp_id_verified,
        "whatsapp_id_locked": getattr(current_user, "whatsapp_id_locked", False) or False,
        "country": current_user.country,
        "country_source": current_user.country_source,
        "showcase_badge_ids": getattr(current_user, "showcase_badge_ids", None) or [],
    }
    
    # Lookup referrer if exists
    if referred_by_code:
        result = await db.execute(
            select(models.User).where(models.User.referral_code == referred_by_code)
        )
        referrer = result.scalars().first()
        if referrer:
            # Format: DisplayName or Username if no display name
            referrer_name = referrer.display_name or referrer.username
            response_data["referred_by_display_name"] = referrer_name
    
    return response_data

@router.put("/users/me/profile", response_model=schemas.UserResponse)
async def update_profile(
    profile: schemas.UpdateProfileRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Update user profile"""
    await db.merge(current_user)

    locked = await db.execute(
        select(models.User)
        .where(models.User.id == current_user.id)
        .with_for_update()
    )
    user = locked.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if profile.display_name is not None:
        user.display_name = profile.display_name

    confirm = bool(profile.confirm_social_reward_revocation)
    platforms_needing_confirm = set()
    social_changes = []

    for field, prefix in SOCIAL_FIELD_PREFIXES:
        new_raw = getattr(profile, field)
        if new_raw is None:
            continue
        new_norm = normalize_social_value(new_raw)
        old_norm = normalize_social_value(getattr(user, field))
        if new_norm == old_norm:
            continue
        if getattr(user, f"{prefix}_id_verified", False):
            platforms_needing_confirm.add(prefix)
        social_changes.append((field, prefix, new_norm))

    if platforms_needing_confirm and not confirm:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "error_code": SOCIAL_CHANGE_CONFIRM_ERROR,
                "platforms": sorted(platforms_needing_confirm),
                "user_message": (
                    "Changing this social ID will remove your current reward until the new ID is verified. "
                    "Do you want to continue?"
                ),
            },
        )

    for field, prefix, new_norm in social_changes:
        old_raw = getattr(user, field)
        old_norm = normalize_social_value(old_raw)
        verified = getattr(user, f"{prefix}_id_verified", False)
        if verified:
            await revoke_platform_mission_rewards(
                db,
                user,
                prefix,
                "social_id_changed",
                extra_detail="profile_update",
            )
            setattr(user, f"{prefix}_id_old", old_raw)
            setattr(user, field, new_norm)
            setattr(user, f"{prefix}_id_verified", False)
            setattr(user, f"{prefix}_id_locked", False)
            if FraudDetectionService.should_log_social_profile_change(
                old_norm=old_norm,
                new_norm=new_norm,
                verified_change=True,
            ):
                await FraudDetectionService.log_suspicious_activity(
                    db,
                    user.id,
                    "SOCIAL_PROFILE_CHANGED",
                    f"Confirmed change {prefix} ID from '{old_norm}' to '{new_norm}' (mission rewards revoked)",
                )
        else:
            setattr(user, field, new_norm)
            if FraudDetectionService.should_log_social_profile_change(
                old_norm=old_norm,
                new_norm=new_norm,
                verified_change=False,
            ):
                await FraudDetectionService.log_suspicious_activity(
                    db,
                    user.id,
                    "SOCIAL_PROFILE_CHANGED",
                    f"Changed {prefix} ID from '{old_norm}' to '{new_norm}'",
                )

    if profile.country is not None:
        user.country = profile.country.upper()[:2]

    if profile.country_source is not None:
        user.country_source = profile.country_source

    await FraudDetectionService.check_duplicate_socials(
        db,
        user.id,
        profile.discord_id,
        profile.telegram_id,
        profile.x_id,
    )

    await db.commit()
    await db.refresh(user)
    return user


SHOWCASE_BADGE_MAX = 6


@router.put("/users/me/showcase-badges", response_model=schemas.UserResponse)
async def update_showcase_badges(
    body: schemas.UpdateShowcaseBadgesRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """Pin up to 6 earned badges on your profile (order preserved)."""
    if len(body.badge_ids) > SHOWCASE_BADGE_MAX:
        raise HTTPException(
            status_code=400,
            detail=f"At most {SHOWCASE_BADGE_MAX} showcase badges allowed",
        )
    seen = set()
    ordered: List[uuid.UUID] = []
    for bid in body.badge_ids:
        if bid in seen:
            continue
        seen.add(bid)
        ordered.append(bid)
    for bid in ordered:
        r = await db.execute(
            select(models.UserBadge).where(
                models.UserBadge.id == bid,
                models.UserBadge.user_id == current_user.id,
            )
        )
        if r.scalars().first() is None:
            raise HTTPException(status_code=400, detail=f"Badge not found or not yours: {bid}")
    user = await db.merge(current_user)
    user.showcase_badge_ids = [str(x) for x in ordered]
    await db.commit()
    await db.refresh(user)
    return user


@router.put("/users/me/password")
async def change_password(
    request: schemas.ChangePasswordRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Change user password from within an authenticated session, confirming old password"""
    if not auth.verify_password(request.old_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect old password"
        )
    
    current_user.hashed_password = auth.get_password_hash(request.new_password)
    db.add(current_user)
    await db.commit()
    
    return {"message": "Password updated successfully"}

@router.api_route(
    "/users/me/referred-by",
    methods=["POST", "PUT"],
    response_model=schemas.UserResponse,
)
async def update_referred_by(
    request: schemas.UpdateReferredByRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Set referred_by once post-signup if not already linked to a referrer."""
    current_user = await db.merge(current_user)
    code = request.referral_code.strip().lower()

    existing = (current_user.referred_by or "").strip().lower()
    if existing:
        if existing == code:
            await db.refresh(current_user)
            return current_user
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "error_code": "referral_already_set",
                "message": "Referrer is already set and cannot be changed",
            },
        )

    result = await db.execute(
        select(models.User).where(func.lower(models.User.referral_code) == code)
    )
    referrer = result.scalars().first()

    if not referrer:
        log_referral_milestone(
            "referral_assignment_rejected",
            trigger="referred_by_endpoint",
            referee_user_id=str(current_user.id),
            error_code=REFERRAL_ERR_REFERRER_NOT_FOUND,
        )
        log_referral_audit(
            "referred_by_invalid_code", user_id=str(current_user.id), code=code
        )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "error_code": REFERRAL_ERR_REFERRER_NOT_FOUND,
                "message": "Invalid or unknown referral code",
            },
        )

    ok, err_detail = await can_set_referred_by(
        db, current_user, referrer=referrer, proposed_code_lower=code
    )
    if not ok:
        ec = (
            err_detail.get("error_code")
            if isinstance(err_detail, dict)
            else None
        )
        log_referral_milestone(
            "referral_assignment_rejected",
            trigger="referred_by_endpoint",
            referee_user_id=str(current_user.id),
            referrer_user_id=str(referrer.id),
            error_code=ec,
        )
        log_referral_audit(
            "referred_by_blocked",
            user_id=str(current_user.id),
            detail=err_detail,
        )
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=err_detail)

    current_user.referred_by = code
    from services.referral_bonus import ensure_referral_row

    await ensure_referral_row(
        db, referrer, current_user, trigger="referred_by_endpoint"
    )
    await grant_referral_signup_bonuses(db, current_user)
    await db.commit()
    await db.refresh(current_user)
    log_referral_audit(
        "referred_by_set",
        referee_id=str(current_user.id),
        referrer_id=str(referrer.id),
    )
    return current_user

@router.post("/users/me/reset-social-id")
async def reset_social_id(
    request: schemas.ResetSocialIdRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """
    Reset a verified social ID:
    - Revokes mission rewards for that platform (ledger + audit)
    - Moves current ID to old tracking column, clears ID, unverified, unlocked
    """
    valid_platforms = ['discord', 'telegram', 'x', 'facebook', 'whatsapp']
    platform = request.platform.lower()
    if platform not in valid_platforms:
        raise HTTPException(status_code=400, detail="Invalid platform")

    id_attr = f"{platform}_id"
    verified_attr = f"{platform}_id_verified"
    locked_attr = f"{platform}_id_locked"
    old_attr = f"{platform}_id_old"

    await db.merge(current_user)
    locked = await db.execute(
        select(models.User)
        .where(models.User.id == current_user.id)
        .with_for_update()
    )
    user = locked.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    current_val = getattr(user, id_attr)
    is_verified = getattr(user, verified_attr)

    if not is_verified:
        raise HTTPException(status_code=400, detail="ID is not verified, no need to reset")

    revoked = await revoke_platform_mission_rewards(
        db, user, platform, "social_id_reset", extra_detail="reset_social_id endpoint"
    )
    setattr(user, old_attr, current_val)
    setattr(user, id_attr, None)
    setattr(user, verified_attr, False)
    setattr(user, locked_attr, False)
    await write_audit(
        db,
        user.id,
        "SOCIAL_ID_RESET",
        platform,
        f"Cleared verified social id, prior_value={current_val}",
        revoked,
    )
    await db.commit()
    return {"message": f"{platform.capitalize()} ID reset successfully", "revoked_amount": revoked}

@router.post("/forgot-password")
async def forgot_password(
    http_request: Request,
    payload: schemas.ResendCodeRequest,
    db: AsyncSession = Depends(database.get_db),
):
    """
    Initiate password reset:
    - Finds user by email
    - Generates 6-digit code
    - Sends email
    """
    ip = client_ip_from_request(http_request)
    email_key = str(payload.email).strip().lower()
    await enforce_rate_limit(
        f"forgot:ip:{ip}", settings.AUTH_RL_FORGOT_PER_HOUR_IP, 3600.0
    )
    await enforce_rate_limit(
        f"forgot:email:{email_key}",
        settings.AUTH_RL_FORGOT_PER_HOUR_EMAIL,
        3600.0,
    )

    result = await db.execute(
        select(models.User).where(models.User.email == payload.email)
    )
    user = result.scalars().first()

    if not user:
        return {"message": auth_messages.FORGOT_PASSWORD_ACK}

    reset_code = generate_verification_code()
    reset_expires = EmailService.get_verification_expiry()

    user.password_reset_code = reset_code
    user.password_reset_expires = reset_expires
    user.verification_code = None
    user.verification_code_expires = None

    email = user.email
    username = user.username

    await db.commit()

    sent = await EmailService.send_password_reset_email(email, reset_code, username)
    if not sent:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=auth_messages.EMAIL_DELIVERY_UNAVAILABLE,
        )
    return {"message": auth_messages.FORGOT_PASSWORD_ACK}

@router.post("/reset-password")
async def reset_password(
    http_request: Request,
    payload: schemas.ResetPasswordRequest,
    db: AsyncSession = Depends(database.get_db),
):
    """
    Reset password with OTP (password-reset channel only; not email verification codes).
    """
    ip = client_ip_from_request(http_request)
    await enforce_rate_limit(
        f"reset:ip:{ip}", settings.AUTH_RL_RESET_PER_MINUTE_IP, 60.0
    )

    result = await db.execute(select(models.User).where(models.User.email == payload.email))
    user = result.scalars().first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=auth_messages.INVALID_RESET_CODE,
        )

    rc = user.password_reset_code
    if (
        not rc
        or not payload.code
        or not secrets.compare_digest(rc, payload.code)
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=auth_messages.INVALID_RESET_CODE,
        )

    if (
        not user.password_reset_expires
        or datetime.utcnow() > user.password_reset_expires
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=auth_messages.INVALID_RESET_CODE,
        )

    user.hashed_password = auth.get_password_hash(payload.new_password)
    user.password_reset_code = None
    user.password_reset_expires = None

    await auth.revoke_all_refresh_tokens_for_user(user.id, db)

    await db.commit()
    return {"message": "Password updated successfully. Please login."}
@router.get("/users/me/balance-details", response_model=schemas.BalanceDetailsResponse)
async def get_balance_details(
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Get category-wise earnings breakdown and withdrawal permissions"""
    from services.session_manager import EarningsManager, SessionManager
    
    # 1. Get breakdown
    breakdown_dict = await EarningsManager.calculate_earnings_breakdown(current_user.id, db)
    earnings_breakdown = schemas.EarningsBreakdownResponse(**breakdown_dict)
    
    # 2. Get Primary wallet
    wallet_result = await db.execute(
        select(models.Wallet)
        .where(models.Wallet.user_id == current_user.id)
        .where(models.Wallet.is_primary == True)
    )
    primary_wallet = wallet_result.scalars().first()
    
    # 3. Format response
    config = await SessionManager.get_admin_config(db)
    return schemas.BalanceDetailsResponse(
        primary_wallet=schemas.WalletSummaryResponse.model_validate(primary_wallet) if primary_wallet else None,
        earnings_breakdown=earnings_breakdown,
        withdrawal_permissions={
            "mining": current_user.can_withdraw_mining,
            "referrals": current_user.can_withdraw_referrals,
            "missions": current_user.can_withdraw_missions,
            "games": current_user.can_withdraw_games,
            "game_boosts": current_user.can_withdraw_game_boosts
        },
        total_balance=current_user.balance,
        global_withdrawal_enabled=config.global_withdrawal_enabled
    )

@router.get("/users/me/earnings-history", response_model=List[schemas.EarningsLedgerEntryResponse])
async def get_earnings_history(
    skip: int = 0,
    limit: int = 50,
    reward_type: Optional[str] = None,
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Get complete earnings history for the user"""
    query = select(models.EarningsLedger).where(models.EarningsLedger.user_id == current_user.id)
    
    if reward_type:
        query = query.where(models.EarningsLedger.reward_type == reward_type)
        
    result = await db.execute(
        query.order_by(models.EarningsLedger.created_at.desc())
        .offset(skip).limit(limit)
    )
    return result.scalars().all()

@router.post("/users/me/withdraw")
async def request_withdrawal(
    reward_type: str,
    current_user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Request a withdrawal for a specific reward type"""
    from services.session_manager import EarningsManager, SessionManager
    
    # 0. Global Permission Check
    config = await SessionManager.get_admin_config(db)
    if not config.global_withdrawal_enabled:
        raise HTTPException(status_code=403, detail="Withdrawals are currently disabled globally by the administrator.")

    # 1. Define Categories and Permission Checks
    mission_types = [
        models.RewardType.MISSION_COMPLETION,
        models.RewardType.SOCIAL_X,
        models.RewardType.SOCIAL_DISCORD,
        models.RewardType.SOCIAL_TELEGRAM,
        models.RewardType.SOCIAL_FACEBOOK,
    ]
    
    # 2. Amount and Permission Check
    breakdown = await EarningsManager.calculate_earnings_breakdown(current_user.id, db)
    
    if reward_type == "MISSIONS_ALL":
        amount = sum(breakdown.get(rt.value, 0.0) for rt in mission_types)
        if not current_user.can_withdraw_missions:
            raise HTTPException(status_code=403, detail="Mission withdrawals are disabled for your account.")
        # For the payout record, we'll use MISSION_COMPLETION as the primary type
        record_reward_type = models.RewardType.MISSION_COMPLETION 
    else:
        # Standard types
        try:
            rt_enum = models.RewardType(reward_type)
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid reward type: {reward_type}")
            
        perm_map = {
            models.RewardType.MINING_BASE: current_user.can_withdraw_mining,
            models.RewardType.MINING_REFERRAL_BOOST: current_user.can_withdraw_referrals,
            models.RewardType.MISSION_COMPLETION: current_user.can_withdraw_missions,
            models.RewardType.GAME_REWARD: current_user.can_withdraw_games,
            models.RewardType.GAME_BOOST: current_user.can_withdraw_game_boosts,
            models.RewardType.SOCIAL_X: current_user.can_withdraw_missions,
            models.RewardType.SOCIAL_DISCORD: current_user.can_withdraw_missions,
            models.RewardType.SOCIAL_TELEGRAM: current_user.can_withdraw_missions,
            models.RewardType.SOCIAL_FACEBOOK: current_user.can_withdraw_missions,
        }
        
        if rt_enum not in perm_map:
             raise HTTPException(status_code=400, detail=f"Non-withdrawable reward type: {reward_type}")
             
        if not perm_map[rt_enum]:
            raise HTTPException(status_code=403, detail=f"Withdrawals for {reward_type} are disabled.")
            
        amount = breakdown.get(rt_enum.value, 0.0)
        record_reward_type = rt_enum

    if amount <= 0:
        raise HTTPException(status_code=400, detail="No earnings found for this category to withdraw.")
        
    # 3. Threshold Check for Games
    if reward_type == "GAME_REWARD" and amount < 100000000.0: # 1 CAT
        raise HTTPException(status_code=400, detail="Game rewards require at least 1 CAT (100,000,000 Catoshi) for withdrawal.")
        
    # 4. Wallet Check
    wallet_result = await db.execute(
        select(models.Wallet)
        .where(models.Wallet.user_id == current_user.id)
        .where(models.Wallet.is_primary == True)
    )
    wallet = wallet_result.scalars().first()
    if not wallet:
        raise HTTPException(status_code=400, detail="Please set a primary wallet address first.")

    # 5. Create Payout Request
    payout = models.Payout(
        user_id=current_user.id,
        catcoin_address=wallet.catcoin_address,
        amount_cat=amount,
        status="pending"
    )
    db.add(payout)
    await db.flush() # Get payout ID
    
    # 6. Create Withdrawal Entry in Ledger (to deduct balance)
    await EarningsManager.create_withdrawal_entry(
        user_id=current_user.id,
        amount=amount,
        payout_id=payout.id,
        db=db
    )
    
    await db.commit()
    return {"message": "Withdrawal request submitted successfully", "payout_id": str(payout.id)}
