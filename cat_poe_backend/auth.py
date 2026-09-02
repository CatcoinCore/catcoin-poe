from datetime import datetime, timedelta
from typing import Optional, Tuple, Union
import uuid
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update
import secrets
import models, schemas, database, config
from services import auth_messages

settings = config.settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password):
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def _as_user_uuid(user_id: Union[str, uuid.UUID]) -> uuid.UUID:
    if isinstance(user_id, uuid.UUID):
        return user_id
    return uuid.UUID(str(user_id))


async def create_refresh_token(
    user_id: Union[str, uuid.UUID],
    db: AsyncSession,
    device_info: str = None,
    family_id: Optional[uuid.UUID] = None,
) -> str:
    """Create a new refresh token row (new rotation family unless family_id is passed)."""
    uid = _as_user_uuid(user_id)
    if family_id is None:
        family_id = uuid.uuid4()
    token = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    refresh_token = models.RefreshToken(
        user_id=uid,
        token=token,
        expires_at=expires_at,
        device_info=device_info,
        family_id=family_id,
    )
    db.add(refresh_token)
    await db.commit()

    return token


async def rotate_refresh_token(
    raw_token: str, db: AsyncSession
) -> Tuple[models.User, str]:
    """
    One-time refresh: revoke presented token, issue a new token in the same family.
    If the presented token was already revoked, treat as replay and revoke the whole family.
    """
    now = datetime.utcnow()
    result = await db.execute(
        select(models.RefreshToken).where(models.RefreshToken.token == raw_token)
    )
    rt = result.scalars().first()

    if not rt:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=auth_messages.INVALID_REFRESH_TOKEN,
        )

    if rt.revoked:
        await db.execute(
            update(models.RefreshToken)
            .where(
                models.RefreshToken.user_id == rt.user_id,
                models.RefreshToken.family_id == rt.family_id,
            )
            .values(revoked=True)
        )
        await db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=auth_messages.INVALID_REFRESH_TOKEN,
        )

    if rt.expires_at <= now:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=auth_messages.INVALID_REFRESH_TOKEN,
        )

    rt.revoked = True
    new_raw = secrets.token_urlsafe(32)
    new_exp = now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    new_row = models.RefreshToken(
        user_id=rt.user_id,
        token=new_raw,
        expires_at=new_exp,
        device_info=rt.device_info,
        family_id=rt.family_id,
        revoked=False,
    )
    db.add(new_row)
    await db.commit()

    ures = await db.execute(select(models.User).where(models.User.id == rt.user_id))
    user = ures.scalars().first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=auth_messages.INVALID_REFRESH_TOKEN,
        )
    return user, new_raw


async def revoke_refresh_token(
    token: str, db: AsyncSession, acting_user_id: uuid.UUID
):
    """Revoke a refresh token; must belong to acting_user_id."""
    result = await db.execute(
        select(models.RefreshToken).where(models.RefreshToken.token == token)
    )
    refresh_token = result.scalars().first()

    if refresh_token:
        if refresh_token.user_id != acting_user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot revoke a refresh token for another user",
            )
        refresh_token.revoked = True
        await db.commit()


async def revoke_all_refresh_tokens_for_user(user_id: uuid.UUID, db: AsyncSession):
    """Mark all refresh tokens revoked for user. Caller should commit."""
    await db.execute(
        update(models.RefreshToken)
        .where(models.RefreshToken.user_id == user_id)
        .values(revoked=True)
    )


async def get_current_user(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(database.get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = schemas.TokenData(username=username)
    except JWTError:
        raise credentials_exception

    result = await db.execute(select(models.User).where(models.User.username == token_data.username))
    user = result.scalars().first()
    if user is None:
        raise credentials_exception
    return user


async def require_admin(user: models.User = Depends(get_current_user)):
    """Require user to be admin"""
    if not user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return user
