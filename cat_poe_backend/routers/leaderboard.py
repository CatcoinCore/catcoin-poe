from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc, and_
from typing import List, Optional
from datetime import datetime, timedelta
import uuid
from pydantic import BaseModel

import models

_LEADERBOARD_LIMIT_CAP = 100


def _clamp_limit(limit: int) -> int:
    return max(1, min(limit, _LEADERBOARD_LIMIT_CAP))
import schemas
import database
from auth import get_current_user
from services.monthly_podium_awards import (
    MonthBounds,
    ledger_where_closed_calendar_month,
    ledger_where_partial_calendar_month,
)

router = APIRouter(
    prefix="/leaderboard",
    tags=["leaderboard"],
    responses={404: {"description": "Not found"}},
)

class LeaderboardEntry(BaseModel):
    id: str
    username: str
    display_name: Optional[str] = None
    country: str = "US"
    balance: float
    rank: int
    
@router.get("/global", response_model=List[LeaderboardEntry])
async def get_global_leaderboard(
    limit: int = 20,
    current_user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """
    Get top miners for the CURRENT MONTH by aggregating EarningsLedger,
    excluding SPECIAL_BONUS rewards.
    """
    limit = _clamp_limit(limit)
    now = datetime.utcnow()

    # Subquery to aggregate earnings by user for the current month excluding special bonuses
    ledger_stmt = (
        select(
            models.EarningsLedger.user_id,
            func.sum(models.EarningsLedger.amount).label("monthly_score")
        )
        .where(
            models.EarningsLedger.reward_type != models.RewardType.SPECIAL_BONUS,
            ledger_where_partial_calendar_month(now),
        )
        .group_by(models.EarningsLedger.user_id)
        .subquery()
    )

    # Main query to join with users and get top performers
    ranking_stmt = (
        select(
            models.User,
            func.coalesce(ledger_stmt.c.monthly_score, 0.0).label("score")
        )
        .outerjoin(ledger_stmt, models.User.id == ledger_stmt.c.user_id)
        .where(models.User.is_admin == False, models.User.is_deleted == False)
        .order_by(desc("score"), models.User.id)
        .limit(limit)
    )

    result = await db.execute(ranking_stmt)
    rows = result.all()
    
    entries = []
    current_user_in_top = False
    
    for i, row in enumerate(rows):
        user, score = row
        rank = i + 1
        
        if user.id == current_user.id:
            current_user_in_top = True
            
        entries.append(
            LeaderboardEntry(
                id=str(user.id),
                username=str(user.username)[:5] + "****" if user.username else "Unknown",
                display_name=user.display_name,
                country=user.country or "US",
                balance=float(score),
                rank=rank
            )
        )
        
    if not current_user_in_top and not current_user.is_admin and not current_user.is_deleted:
        # Calculate current user's monthly score
        user_score_stmt = await db.execute(
            select(func.coalesce(func.sum(models.EarningsLedger.amount), 0.0))
            .where(
                models.EarningsLedger.user_id == current_user.id,
                models.EarningsLedger.reward_type != models.RewardType.SPECIAL_BONUS,
                ledger_where_partial_calendar_month(now),
            )
        )
        user_score = user_score_stmt.scalar()
        
        # Rank is count of users with higher monthly score
        higher_scores_stmt = (
            select(func.count(models.User.id))
            .join(ledger_stmt, models.User.id == ledger_stmt.c.user_id)
            .where(models.User.is_admin == False, models.User.is_deleted == False)
            .where(ledger_stmt.c.monthly_score > user_score)
        )
        rank_query = await db.execute(higher_scores_stmt)
        user_rank = rank_query.scalar() + 1
        
        entries.append(
            LeaderboardEntry(
                id=str(current_user.id),
                username=str(current_user.username)[:5] + "****" if current_user.username else "Unknown",
                display_name=current_user.display_name,
                country=current_user.country or "US",
                balance=float(user_score),
                rank=user_rank
            )
        )
        
    return entries

@router.get("/referred", response_model=List[LeaderboardEntry])
async def get_top_referred_miners(
    limit: int = 10,
    current_user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """
    Get top active miners from the user's referral list.
    """
    limit = _clamp_limit(limit)
    from services.session_manager import SessionManager
    from sqlalchemy import and_
    
    config = await SessionManager.get_admin_config(db)
    sort_by = config.leaderboard_sort_by
    
    score_col = models.User.total_earnings if sort_by == "TOTAL_EARNINGS" else models.User.balance

    ranking_stmt = (
        select(models.User)
        .where(models.User.referred_by == current_user.referral_code, models.User.is_deleted == False)
        .order_by(desc(score_col), models.User.id)
        .limit(limit)
    )

    result = await db.execute(ranking_stmt)
    users = result.scalars().all()
    
    entries = []
    for i, user in enumerate(users):
        score = getattr(user, "total_earnings" if sort_by == "TOTAL_EARNINGS" else "balance") or 0.0
        entries.append(
            LeaderboardEntry(
                id=str(user.id),
                username=str(user.username)[:5] + "****" if user.username else "Unknown",
                display_name=user.display_name,
                country=user.country or "US",
                balance=float(score),
                rank=i + 1
            )
        )
    return entries

@router.get("/badges", response_model=List[schemas.UserBadgeResponse])
async def get_my_badges(
    current_user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """
    Get badges/awards for the current logged-in user.
    """
    result = await db.execute(
        select(models.UserBadge).where(models.UserBadge.user_id == current_user.id)
    )
    badges = result.scalars().all()
    return badges

@router.get("/regional", response_model=List[LeaderboardEntry])
async def get_regional_leaderboard(
    limit: int = 20,
    current_user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """
    Get top miners in the current user's country for the CURRENT MONTH.
    """
    limit = _clamp_limit(limit)
    now = datetime.utcnow()
    country_norm = (current_user.country or "US").strip().upper()[:2]

    ledger_stmt = (
        select(
            models.EarningsLedger.user_id,
            func.sum(models.EarningsLedger.amount).label("monthly_score")
        )
        .where(
            models.EarningsLedger.reward_type != models.RewardType.SPECIAL_BONUS,
            ledger_where_partial_calendar_month(now),
        )
        .group_by(models.EarningsLedger.user_id)
        .subquery()
    )

    ranking_stmt = (
        select(
            models.User,
            func.coalesce(ledger_stmt.c.monthly_score, 0.0).label("score")
        )
        .outerjoin(ledger_stmt, models.User.id == ledger_stmt.c.user_id)
        .where(
            models.User.is_admin == False,
            models.User.is_deleted == False,
            func.upper(func.coalesce(models.User.country, "US")) == country_norm,
        )
        .order_by(desc("score"), models.User.id)
        .limit(limit)
    )

    result = await db.execute(ranking_stmt)
    rows = result.all()

    entries = []
    current_user_in_top = False

    for i, row in enumerate(rows):
        user, score = row
        rank = i + 1

        if user.id == current_user.id:
            current_user_in_top = True

        entries.append(
            LeaderboardEntry(
                id=str(user.id),
                username=str(user.username)[:5] + "****" if user.username else "Unknown",
                display_name=user.display_name,
                country=user.country or "US",
                balance=float(score),
                rank=rank
            )
        )

    if not current_user_in_top and not current_user.is_admin and not current_user.is_deleted:
        user_score_stmt = await db.execute(
            select(func.coalesce(func.sum(models.EarningsLedger.amount), 0.0))
            .where(
                models.EarningsLedger.user_id == current_user.id,
                models.EarningsLedger.reward_type != models.RewardType.SPECIAL_BONUS,
                ledger_where_partial_calendar_month(now),
            )
        )
        user_score = user_score_stmt.scalar()

        higher_scores_stmt = (
            select(func.count(models.User.id))
            .join(ledger_stmt, models.User.id == ledger_stmt.c.user_id)
            .where(
                models.User.is_admin == False,
                models.User.is_deleted == False,
                func.upper(func.coalesce(models.User.country, "US")) == country_norm,
            )
            .where(ledger_stmt.c.monthly_score > user_score)
        )
        rank_query = await db.execute(higher_scores_stmt)
        user_rank = rank_query.scalar() + 1

        entries.append(
            LeaderboardEntry(
                id=str(current_user.id),
                username=str(current_user.username)[:5] + "****" if current_user.username else "Unknown",
                display_name=current_user.display_name,
                country=current_user.country or "US",
                balance=float(user_score),
                rank=user_rank
            )
        )

    return entries

@router.get("/previous-month", response_model=List[LeaderboardEntry])
async def get_previous_month_leaders(
    limit: int = 3,
    db: AsyncSession = Depends(database.get_db)
):
    """
    Get top miners from the PREVIOUS MONTH for the awards section.
    """
    limit = _clamp_limit(limit)
    now = datetime.utcnow()
    # Calculate previous month range
    first_day_this_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    last_day_prev_month = first_day_this_month - timedelta(seconds=1)
    first_day_prev_month = last_day_prev_month.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    prev_bounds = MonthBounds(
        start=first_day_prev_month,
        end=last_day_prev_month,
        year=first_day_prev_month.year,
        month=first_day_prev_month.month,
    )

    ledger_stmt = (
        select(
            models.EarningsLedger.user_id,
            func.sum(models.EarningsLedger.amount).label("monthly_score")
        )
        .where(
            models.EarningsLedger.reward_type != models.RewardType.SPECIAL_BONUS,
            ledger_where_closed_calendar_month(prev_bounds),
        )
        .group_by(models.EarningsLedger.user_id)
        .subquery()
    )

    ranking_stmt = (
        select(
            models.User,
            func.coalesce(ledger_stmt.c.monthly_score, 0.0).label("score")
        )
        .join(ledger_stmt, models.User.id == ledger_stmt.c.user_id)
        .where(models.User.is_admin == False, models.User.is_deleted == False)
        .order_by(desc("score"), models.User.id)
        .limit(limit)
    )

    result = await db.execute(ranking_stmt)
    rows = result.all()

    entries = []
    for i, row in enumerate(rows):
        user, score = row
        entries.append(
            LeaderboardEntry(
                id=str(user.id),
                username=str(user.username)[:5] + "****" if user.username else "Unknown",
                display_name=user.display_name,
                country=user.country or "US",
                balance=float(score),
                rank=i + 1
            )
        )
    return entries


def _mask_username(username: Optional[str]) -> str:
    if not username:
        return "Unknown"
    return str(username)[:5] + "****"


def _user_to_preview(user: models.User, score: float, rank: int) -> schemas.PodiumPreviewEntry:
    return schemas.PodiumPreviewEntry(
        id=str(user.id),
        username=_mask_username(user.username),
        display_name=user.display_name,
        country=user.country or "US",
        balance=float(score),
        rank=rank,
    )


@router.get("/previous-month/summary", response_model=schemas.PreviousMonthSummaryResponse)
async def get_previous_month_summary(
    year: Optional[int] = None,
    month: Optional[int] = None,
    current_user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """Top 3 for last completed month: global, viewer's regional (country), and each game."""
    from services.monthly_podium_awards import (
        resolve_bounds,
        global_top_for_month,
        regional_top_for_month,
        game_top_for_month,
        GAME_TYPES,
    )

    bounds = resolve_bounds(year, month)
    country = (current_user.country or "US").upper()[:2]

    g_rows = await global_top_for_month(db, bounds, 3)
    global_leaders = [_user_to_preview(u, s, i + 1) for i, (u, s) in enumerate(g_rows)]

    r_rows = await regional_top_for_month(db, bounds, country, 3)
    regional_leaders = [_user_to_preview(u, s, i + 1) for i, (u, s) in enumerate(r_rows)]

    games = []
    for gtype in GAME_TYPES:
        gr = await game_top_for_month(db, bounds, gtype, 3)
        games.append(
            schemas.PreviousMonthGamePodium(
                game_type=gtype,
                leaders=[_user_to_preview(u, float(s), i + 1) for i, (u, s) in enumerate(gr)],
            )
        )

    return schemas.PreviousMonthSummaryResponse(
        period_year=bounds.year,
        period_month=bounds.month,
        global_leaders=global_leaders,
        regional_leaders=regional_leaders,
        games=games,
    )
