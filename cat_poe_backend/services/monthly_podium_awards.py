"""
Monthly podium: global (ledger), regional per country (ledger), and per-game (validated sessions).
Badges: monthly_global_podium, monthly_regional_podium, monthly_game_podium.
"""
from __future__ import annotations

from calendar import monthrange
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import List, Sequence, Tuple
import uuid

from sqlalchemy import select, func, desc, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession

import models

TOP_N = 3
BADGE_GLOBAL = "monthly_global_podium"
BADGE_REGIONAL = "monthly_regional_podium"
BADGE_GAME = "monthly_game_podium"
SCOPE_GLOBAL = "GLOBAL"
SCOPE_REGIONAL = "REGIONAL"
SCOPE_GAME = "GAME"
GAME_TYPES: Sequence[str] = (
    "RUNNER",
    "TICTACTOE",
    "SUDOKU",
    "COLLAGE",
    "MINER",
    "ARROW",
    "TWENTY48",
)


@dataclass
class MonthBounds:
    start: datetime
    end: datetime
    year: int
    month: int


def previous_completed_month_bounds(now: datetime | None = None) -> MonthBounds:
    now = now or datetime.utcnow()
    first_this = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    last_prev = first_this - timedelta(seconds=1)
    first_prev = last_prev.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    return MonthBounds(start=first_prev, end=last_prev, year=first_prev.year, month=first_prev.month)


def bounds_for_calendar_month(year: int, month: int) -> MonthBounds:
    start = datetime(year, month, 1, 0, 0, 0, 0)
    last_day = monthrange(year, month)[1]
    end = datetime(year, month, last_day, 23, 59, 59, 999999)
    return MonthBounds(start=start, end=end, year=year, month=month)


def resolve_bounds(year: int | None, month: int | None) -> MonthBounds:
    if year is not None and month is not None:
        return bounds_for_calendar_month(year, month)
    return previous_completed_month_bounds()


def ledger_where_closed_calendar_month(bounds: MonthBounds):
    """
    Rows credited to a closed calendar month:
    - Mining / daily buckets: aggregation_date in [bounds.start.date(), bounds.end.date()]
    - Other ledger rows (games, missions, withdrawals): created_at within bounds.
    Using created_at alone misses rows whose credited calendar day is aggregation_date
    when DB timestamps don't align with that month boundary.
    """
    start_d = bounds.start.date()
    end_d = bounds.end.date()
    return or_(
        and_(
            models.EarningsLedger.aggregation_date.isnot(None),
            models.EarningsLedger.aggregation_date >= start_d,
            models.EarningsLedger.aggregation_date <= end_d,
        ),
        and_(
            models.EarningsLedger.aggregation_date.is_(None),
            models.EarningsLedger.created_at >= bounds.start,
            models.EarningsLedger.created_at <= bounds.end,
        ),
    )


def ledger_where_partial_calendar_month(now: datetime | None = None):
    """Same attribution rules through UTC `now` (month-to-date)."""
    now = now or datetime.utcnow()
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    today_d = now.date()
    return or_(
        and_(
            models.EarningsLedger.aggregation_date.isnot(None),
            models.EarningsLedger.aggregation_date >= month_start.date(),
            models.EarningsLedger.aggregation_date <= today_d,
        ),
        and_(
            models.EarningsLedger.aggregation_date.is_(None),
            models.EarningsLedger.created_at >= month_start,
            models.EarningsLedger.created_at <= now,
        ),
    )


def _ledger_subquery(bounds: MonthBounds):
    return (
        select(
            models.EarningsLedger.user_id,
            func.sum(models.EarningsLedger.amount).label("monthly_score"),
        )
        .where(
            models.EarningsLedger.reward_type != models.RewardType.SPECIAL_BONUS,
            ledger_where_closed_calendar_month(bounds),
        )
        .group_by(models.EarningsLedger.user_id)
        .subquery()
    )


async def global_top_for_month(
    db: AsyncSession, bounds: MonthBounds, limit: int
) -> List[Tuple[models.User, float]]:
    ledger_stmt = _ledger_subquery(bounds)
    ranking_stmt = (
        select(
            models.User,
            func.coalesce(ledger_stmt.c.monthly_score, 0.0).label("score"),
        )
        .join(ledger_stmt, models.User.id == ledger_stmt.c.user_id)
        .where(models.User.is_admin == False, models.User.is_deleted == False)
        .order_by(desc("score"), models.User.id)
        .limit(limit)
    )
    result = await db.execute(ranking_stmt)
    return [(row[0], float(row[1])) for row in result.all()]


async def regional_top_for_month(
    db: AsyncSession, bounds: MonthBounds, country: str, limit: int
) -> List[Tuple[models.User, float]]:
    ledger_stmt = _ledger_subquery(bounds)
    cc = country.strip().upper()[:2] if country else "US"
    ranking_stmt = (
        select(
            models.User,
            func.coalesce(ledger_stmt.c.monthly_score, 0.0).label("score"),
        )
        .join(ledger_stmt, models.User.id == ledger_stmt.c.user_id)
        .where(
            models.User.is_admin == False,
            models.User.is_deleted == False,
            func.upper(func.coalesce(models.User.country, "US")) == cc,
        )
        .order_by(desc("score"), models.User.id)
        .limit(limit)
    )
    result = await db.execute(ranking_stmt)
    return [(row[0], float(row[1])) for row in result.all()]


async def countries_with_ledger_activity(db: AsyncSession, bounds: MonthBounds) -> List[str]:
    ledger_stmt = _ledger_subquery(bounds)
    q = (
        select(func.upper(func.coalesce(models.User.country, "US")))
        .join(ledger_stmt, models.User.id == ledger_stmt.c.user_id)
        .where(models.User.is_admin == False, models.User.is_deleted == False)
        .distinct()
    )
    result = await db.execute(q)
    out = []
    for row in result.all():
        c = row[0]
        if c and len(str(c).strip()) == 2:
            out.append(str(c).upper())
    return sorted(set(out))


async def game_top_for_month(
    db: AsyncSession, bounds: MonthBounds, game_type: str, limit: int
) -> List[Tuple[models.User, int]]:
    session_ts = func.coalesce(models.GameSession.end_time, models.GameSession.start_time)
    inner = (
        select(
            models.GameSession.user_id,
            func.max(models.GameSession.score).label("best_score"),
        )
        .where(
            models.GameSession.game_type == game_type,
            models.GameSession.validated == True,
            session_ts >= bounds.start,
            session_ts <= bounds.end,
        )
        .group_by(models.GameSession.user_id)
        .subquery()
    )
    q = (
        select(models.User, inner.c.best_score)
        .join(inner, models.User.id == inner.c.user_id)
        .where(models.User.is_admin == False, models.User.is_deleted == False)
        .order_by(desc(inner.c.best_score), models.User.id)
        .limit(limit)
    )
    result = await db.execute(q)
    return [(row[0], int(row[1])) for row in result.all()]


async def _existing_badge(
    db: AsyncSession,
    user_id: uuid.UUID,
    badge_type: str,
    bounds: MonthBounds,
    *,
    award_scope: str,
    region_code: str | None = None,
    game_type: str | None = None,
) -> bool:
    conds = [
        models.UserBadge.user_id == user_id,
        models.UserBadge.badge_type == badge_type,
        models.UserBadge.period_year == bounds.year,
        models.UserBadge.period_month == bounds.month,
        models.UserBadge.award_scope == award_scope,
    ]
    if region_code is not None:
        conds.append(models.UserBadge.region_code == region_code)
    if game_type is not None:
        conds.append(models.UserBadge.game_type == game_type)
    r = await db.execute(select(models.UserBadge).where(*conds))
    return r.scalars().first() is not None


async def award_global_monthly_podium(
    db: AsyncSession,
    year: int | None = None,
    month: int | None = None,
) -> Tuple[int, int, List[uuid.UUID], List[uuid.UUID]]:
    bounds = resolve_bounds(year, month)
    winners = await global_top_for_month(db, bounds, TOP_N)
    awarded: List[uuid.UUID] = []
    skipped: List[uuid.UUID] = []

    for rank, (user, score) in enumerate(winners, start=1):
        if await _existing_badge(db, user.id, BADGE_GLOBAL, bounds, award_scope=SCOPE_GLOBAL):
            skipped.append(user.id)
            continue
        description = (
            f"Ranked #{rank} on the global monthly leaderboard for {bounds.year}-{bounds.month:02d} "
            f"by total catoshi credited that month (mining, missions, games; special bonuses excluded). "
            f"Monthly total: {score:.0f} catoshi."
        )
        db.add(
            models.UserBadge(
                id=uuid.uuid4(),
                user_id=user.id,
                badge_type=BADGE_GLOBAL,
                description=description,
                awarded_at=datetime.utcnow(),
                period_year=bounds.year,
                period_month=bounds.month,
                podium_rank=rank,
                award_scope=SCOPE_GLOBAL,
                region_code=None,
                game_type=None,
            )
        )
        awarded.append(user.id)

    await db.commit()
    return bounds.year, bounds.month, awarded, skipped


async def award_regional_monthly_podiums(
    db: AsyncSession,
    year: int | None = None,
    month: int | None = None,
) -> Tuple[int, int, List[uuid.UUID], List[uuid.UUID]]:
    bounds = resolve_bounds(year, month)
    countries = await countries_with_ledger_activity(db, bounds)
    awarded: List[uuid.UUID] = []
    skipped: List[uuid.UUID] = []

    for country in countries:
        winners = await regional_top_for_month(db, bounds, country, TOP_N)
        for rank, (user, score) in enumerate(winners, start=1):
            if await _existing_badge(
                db, user.id, BADGE_REGIONAL, bounds, award_scope=SCOPE_REGIONAL, region_code=country
            ):
                skipped.append(user.id)
                continue
            description = (
                f"Ranked #{rank} in {country} for {bounds.year}-{bounds.month:02d} "
                f"by total catoshi credited that month (mining, missions, games; special bonuses excluded). "
                f"Monthly total: {score:.0f} catoshi."
            )
            db.add(
                models.UserBadge(
                    id=uuid.uuid4(),
                    user_id=user.id,
                    badge_type=BADGE_REGIONAL,
                    description=description,
                    awarded_at=datetime.utcnow(),
                    period_year=bounds.year,
                    period_month=bounds.month,
                    podium_rank=rank,
                    award_scope=SCOPE_REGIONAL,
                    region_code=country,
                    game_type=None,
                )
            )
            awarded.append(user.id)

    await db.commit()
    return bounds.year, bounds.month, awarded, skipped


async def award_game_monthly_podiums(
    db: AsyncSession,
    year: int | None = None,
    month: int | None = None,
) -> Tuple[int, int, List[uuid.UUID], List[uuid.UUID]]:
    bounds = resolve_bounds(year, month)
    awarded: List[uuid.UUID] = []
    skipped: List[uuid.UUID] = []

    for gtype in GAME_TYPES:
        winners = await game_top_for_month(db, bounds, gtype, TOP_N)
        for rank, (user, best_score) in enumerate(winners, start=1):
            if await _existing_badge(
                db, user.id, BADGE_GAME, bounds, award_scope=SCOPE_GAME, game_type=gtype
            ):
                skipped.append(user.id)
                continue
            description = (
                f"Ranked #{rank} on the {gtype} leaderboard for {bounds.year}-{bounds.month:02d} "
                f"by best validated session score in that calendar month. Best score: {best_score}."
            )
            db.add(
                models.UserBadge(
                    id=uuid.uuid4(),
                    user_id=user.id,
                    badge_type=BADGE_GAME,
                    description=description,
                    awarded_at=datetime.utcnow(),
                    period_year=bounds.year,
                    period_month=bounds.month,
                    podium_rank=rank,
                    award_scope=SCOPE_GAME,
                    region_code=None,
                    game_type=gtype,
                )
            )
            awarded.append(user.id)

    await db.commit()
    return bounds.year, bounds.month, awarded, skipped


async def award_all_monthly_podiums(
    db: AsyncSession,
    year: int | None = None,
    month: int | None = None,
) -> dict:
    """Run global, regional, and game awards sequentially (each commits)."""
    gy, gm, ga, gs = await award_global_monthly_podium(db, year=year, month=month)
    _y, _m, ra, rs = await award_regional_monthly_podiums(db, year=year, month=month)
    _y2, _m2, wa, ws = await award_game_monthly_podiums(db, year=year, month=month)
    return {
        "period_year": gy,
        "period_month": gm,
        "global_awarded": ga,
        "global_skipped": gs,
        "regional_awarded_count": len(ra),
        "regional_skipped_count": len(rs),
        "game_awarded_count": len(wa),
        "game_skipped_count": len(ws),
    }
