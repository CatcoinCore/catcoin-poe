from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from sqlalchemy.dialects.postgresql import insert as pg_insert
from datetime import datetime, timedelta
from typing import Optional
import secrets
import uuid
import random

import auth
import models
import schemas
import database
import json
from services.session_manager import SessionManager

router = APIRouter(prefix="/game", tags=["game"])

_GAME_LB_LIMIT_CAP = 100


def _mask_username(username: Optional[str]) -> str:
    if not username:
        return "Unknown"
    return str(username)[:5] + "****"


def _load_game_reward_config(admin_config: models.AdminConfig) -> dict:
    """Parse game_reward_config from DB; no router-level fallback JSON."""
    raw = admin_config.game_reward_config
    if raw is None or not str(raw).strip():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "game_reward_config is missing in admin_config. "
                "Run: python seed_admin_game_config.py"
            ),
        )
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="game_reward_config is not valid JSON",
        )

# Anti-cheat: max coins a player can collect per second of gameplay
MAX_COINS_PER_SECOND = 10
# Tunnel Miner (MINER): generous caps vs session duration for leaderboard integrity
MAX_MINER_SCORE_PER_SECOND = 2200
MAX_MINER_DEPTH_PER_SECOND = 6
# 2048 (TWENTY48): score scales reward; clamp reported score vs session length
MAX_TWENTY48_SCORE_PER_SECOND = 450
TWENTY48_SCORE_DIVISOR_FOR_BONUS = 5  # +1 catoshi per this many game points
TWENTY48_MAX_REWARD_CATOSHI = 2_000_000
# Tile Swap (TILE_SWAP, Flame): swap-match puzzle with a score goal and a
# limited move budget. Score clamp scales with session length; reward fires
# only when the player reaches MIN_TILE_SWAP_SCORE_FOR_REWARD before moves
# run out. See cat_poe/lib/games/tile_swap/tile_swap_board.dart for the
# client-side rules.
MAX_TILE_SWAP_SCORE_PER_SECOND = 380
MIN_TILE_SWAP_SCORE_FOR_REWARD = 750
# Minimum session duration in seconds (reject impossibly short games)
MIN_SESSION_DURATION_SECONDS = 3
# Maximum session duration in seconds (reject stale sessions - 1 hour)
MAX_SESSION_DURATION_SECONDS = 3600


@router.post("/start", response_model=schemas.GameSessionStartResponse)
async def start_game_session(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """Start a new game session. Returns a session token the client must submit with results."""
    session_token = secrets.token_urlsafe(32)

    game_session = models.GameSession(
        user_id=user.id,
        session_token=session_token,
        start_time=datetime.utcnow(),
    )
    db.add(game_session)
    await db.commit()
    await db.refresh(game_session)

    return schemas.GameSessionStartResponse(
        session_id=game_session.id,
        session_token=session_token,
    )


@router.post("/submit", response_model=schemas.GameSessionResponse)
async def submit_game_results(
    payload: schemas.GameSessionSubmit,
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """Submit game results for validation and reward calculation."""

    # 1. Look up the session by token
    result = await db.execute(
        select(models.GameSession).where(
            models.GameSession.session_token == payload.session_token,
            models.GameSession.user_id == user.id,
        )
    )
    session = result.scalars().first()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired session token",
        )

    if session.validated:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session already submitted",
        )

    # 2. Validate timing
    now = datetime.utcnow()
    duration_seconds = (now - session.start_time).total_seconds()

    if duration_seconds < MIN_SESSION_DURATION_SECONDS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session duration too short — suspected cheating",
        )

    if duration_seconds > MAX_SESSION_DURATION_SECONDS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session expired",
        )

    # 3. Game-specific logic: reward rules from admin_config (database)
    game_type = payload.game_type or "RUNNER"
    admin_config = await SessionManager.get_admin_config(db)
    game_reward_config = _load_game_reward_config(admin_config)
    config = game_reward_config.get(game_type)

    if game_type == "MINER" and (not config or config.get("reward") is None):
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="MINER is not configured in game_reward_config (add MINER or re-run seed_admin_game_config.py)",
        )

    if game_type == "TILE_SWAP":
        # Anti-cheat: a score below the minimum simply means the player didn't
        # clear enough matches; not an error — but also no reward, and don't
        # consume a cooldown slot. Returning 400 mirrors TWENTY48's shape.
        if int(payload.score) < MIN_TILE_SWAP_SCORE_FOR_REWARD:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "TILE_SWAP reward requires score >= "
                    f"{MIN_TILE_SWAP_SCORE_FOR_REWARD}"
                ),
            )

    if game_type == "TWENTY48":
        best_tile = int(payload.distance_meters)
        if best_tile < 2048:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="TWENTY48 reward requires reaching the 2048 tile",
            )
        if best_tile > 1_048_576:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid TWENTY48 tile value",
            )

    reward_catoshi = payload.coins_collected  # Default for RUNNER
    
    if config and config["reward"] is not None:
        max_games = config.get("max_games")
        cooldown_hours = config.get("cooldown_hours")
        if max_games is None or cooldown_hours is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Game {game_type} is not configured for rewards",
            )
        max_games = int(max_games)
        cooldown_hours = int(cooldown_hours)

        # 3.1 Ensure row exists (idempotent) then lock for concurrent-submit safety
        await db.execute(
            pg_insert(models.GameCooldown)
            .values(
                user_id=user.id,
                game_type=game_type,
                play_count=0,
                last_updated_at=now,
            )
            .on_conflict_do_nothing(constraint="_user_game_cooldown_uc")
        )
        cooldown_result = await db.execute(
            select(models.GameCooldown)
            .where(
                models.GameCooldown.user_id == user.id,
                models.GameCooldown.game_type == game_type,
            )
            .with_for_update()
        )
        cooldown = cooldown_result.scalars().one()

        # 3.2 If a prior cooldown ended, start a fresh window (handles stale rows)
        if cooldown.cooldown_until is not None and now >= cooldown.cooldown_until:
            cooldown.play_count = 0
            cooldown.cooldown_until = None

        # 3.3 Active lockout: must wait for cooldown window
        if cooldown.cooldown_until is not None and now < cooldown.cooldown_until:
            wait_minutes = int((cooldown.cooldown_until - now).total_seconds() / 60)
            wait_time = f"{wait_minutes} minutes" if wait_minutes > 0 else "a few seconds"
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Cooldown active for {game_type}. Limit reached ({max_games}). Next session available in {wait_time}.",
            )

        # 3.4 At limit without an active cooldown (inconsistent state) — reset before counting this play
        if cooldown.play_count >= max_games:
            cooldown.play_count = 0
            cooldown.cooldown_until = None

        reward_catoshi = config["reward"]
        cooldown.play_count += 1
        cooldown.last_updated_at = now

        if cooldown.play_count >= max_games:
            cooldown.cooldown_until = now + timedelta(hours=cooldown_hours)

    # 4. Anti-cheat for RUNNER game
    validated_score = int(payload.score)
    validated_distance = int(payload.distance_meters)
    if game_type == "RUNNER":
        max_possible_coins = int(duration_seconds * MAX_COINS_PER_SECOND)
        validated_coins = min(payload.coins_collected, max_possible_coins)
        reward_catoshi = validated_coins
    else:
        # For fixed-reward games, we used the config reward
        validated_coins = reward_catoshi

    if game_type == "MINER":
        max_score = int(duration_seconds * MAX_MINER_SCORE_PER_SECOND)
        validated_score = max(0, min(validated_score, max_score))
        max_depth = int(duration_seconds * MAX_MINER_DEPTH_PER_SECOND) + 8
        validated_distance = max(0, min(validated_distance, max_depth))

    if game_type == "TWENTY48":
        max_tw_score = int(duration_seconds * MAX_TWENTY48_SCORE_PER_SECOND)
        validated_score = max(0, min(validated_score, max_tw_score))
        base_reward = int(config["reward"]) if config and config.get("reward") is not None else 75
        bonus = validated_score // TWENTY48_SCORE_DIVISOR_FOR_BONUS
        reward_catoshi = min(
            TWENTY48_MAX_REWARD_CATOSHI,
            base_reward + bonus,
        )
        validated_coins = reward_catoshi

    if game_type == "TILE_SWAP":
        # Clamp reported score against perfect-play ceiling so a tampered
        # client can't inflate the leaderboard. The reward itself comes from
        # admin_config.game_reward_config (flat per round) and is already
        # applied via the cooldown / config branch above.
        max_ts_score = int(duration_seconds * MAX_TILE_SWAP_SCORE_PER_SECOND)
        validated_score = max(0, min(validated_score, max_ts_score))

    # 5. Update game session
    session.end_time = now
    session.score = validated_score
    session.coins_collected = validated_coins
    session.distance_meters = validated_distance
    session.game_type = game_type
    session.validated = True

    # 6. Game boost: every 20th completed rewarded game (any type), before adding
    # this session's GameReward so the COUNT stays correct (same boost matrix as before).
    awarded_boost = None
    boost_pct_out: Optional[float] = None
    boost_dur_out: Optional[int] = None

    gr_count_result = await db.execute(
        select(func.count()).select_from(models.GameReward).where(
            models.GameReward.user_id == user.id
        )
    )
    play_number = (gr_count_result.scalar() or 0) + 1

    if play_number % 20 == 0:
        boost_percentage, boost_duration = 5.0, 60
        boost_matrix = {}
        raw_boost = admin_config.game_boost_config
        if raw_boost and str(raw_boost).strip():
            try:
                boost_matrix = json.loads(raw_boost)
            except json.JSONDecodeError:
                boost_matrix = {}
        if isinstance(boost_matrix, dict) and boost_matrix:
            keys = list(boost_matrix.keys())
            selected_perc_str = random.choice(keys)
            boost_percentage = float(selected_perc_str)
            durations = boost_matrix[selected_perc_str]
            if durations:
                boost_duration = random.choice(durations)
        else:
            boost_percentage = random.choice([5.0, 10.0, 15.0, 20.0])
            boost_duration = random.choice([60, 120, 180, 240, 360])

        awarded_boost = models.UserGameBoost(
            user_id=user.id,
            percentage=boost_percentage,
            duration_minutes=boost_duration,
            is_used=False,
        )
        db.add(awarded_boost)
        boost_pct_out = boost_percentage
        boost_dur_out = boost_duration

    # 7. Create game reward entry
    game_reward = models.GameReward(
        user_id=user.id,
        session_id=session.id,
        reward_catoshi=reward_catoshi,
    )
    db.add(game_reward)

    # 8. Write to earnings ledger
    ledger_entry = models.EarningsLedger(
        user_id=user.id,
        amount=float(reward_catoshi),
        reward_type=models.RewardType.GAME_REWARD,
        description=f"Game {session.game_type} score:{validated_score}",
        is_verified=True,
    )
    db.add(ledger_entry)

    # 9. Update user balance
    user.balance = (user.balance or 0.0) + float(reward_catoshi)

    from services.referral_bonus import recalculate_for_referee

    await recalculate_for_referee(db, user.id, trigger="game_event")

    await db.commit()
    if awarded_boost:
        await db.refresh(awarded_boost)

    return schemas.GameSessionResponse(
        id=session.id,
        score=session.score,
        coins_collected=session.coins_collected,
        distance_meters=session.distance_meters,
        game_type=session.game_type,
        reward_catoshi=reward_catoshi,
        start_time=session.start_time,
        end_time=session.end_time,
        validated=session.validated,
        game_boost_awarded=awarded_boost is not None,
        game_boost_percentage=boost_pct_out,
        game_boost_duration_minutes=boost_dur_out,
    )


@router.get("/history", response_model=schemas.GameHistoryResponse)
async def get_game_history(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """Get the last 20 validated game sessions for the current user."""

    result = await db.execute(
        select(models.GameSession)
        .where(
            models.GameSession.user_id == user.id,
            models.GameSession.validated == True,
        )
        .order_by(models.GameSession.start_time.desc())
        .limit(20)
    )
    sessions = result.scalars().all()

    # Get total catoshi earned from game rewards
    total_result = await db.execute(
        select(func.coalesce(func.sum(models.GameReward.reward_catoshi), 0)).where(
            models.GameReward.user_id == user.id
        )
    )
    total_catoshi = total_result.scalar()

    session_responses = []
    for s in sessions:
        # Get reward for this session
        reward_result = await db.execute(
            select(models.GameReward.reward_catoshi).where(
                models.GameReward.session_id == s.id
            )
        )
        reward = reward_result.scalar() or 0

        session_responses.append(
            schemas.GameSessionResponse(
                id=s.id,
                score=s.score,
                coins_collected=s.coins_collected,
                distance_meters=s.distance_meters,
                reward_catoshi=reward,
                start_time=s.start_time,
                end_time=s.end_time,
                validated=s.validated,
            )
        )

    return schemas.GameHistoryResponse(
        sessions=session_responses,
        total_catoshi_earned=total_catoshi,
    )

@router.get("/status", response_model=schemas.GameStatusResponse)
async def get_game_status(
    user: models.User = Depends(auth.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """Get current play counts and cooldowns for all games."""
    now = datetime.utcnow()
    
    # 1. Fetch dynamic reward config from DB
    admin_config = await SessionManager.get_admin_config(db)
    game_reward_config = _load_game_reward_config(admin_config)

    # 2. Fetch user's cooldowns
    result = await db.execute(
        select(models.GameCooldown).where(models.GameCooldown.user_id == user.id)
    )
    cooldowns = {c.game_type: c for c in result.scalars().all()}
    
    status_list = []
    for gtype, config in game_reward_config.items():
        cooldown = cooldowns.get(gtype)
        play_count = cooldown.play_count if cooldown else 0
        cooldown_until = cooldown.cooldown_until if cooldown else None
        
        # Reset if cooldown expired (display only; submit path normalizes DB)
        if cooldown_until and now >= cooldown_until:
            play_count = 0
            cooldown_until = None

        max_games = config.get("max_games")
        # Unlimited / not configured: RUNNER is playable; others are coming-soon
        if max_games is None:
            can_play = gtype == "RUNNER"
        else:
            max_games = int(max_games)
            in_cooldown = cooldown_until is not None and now < cooldown_until
            if in_cooldown:
                can_play = False
            elif play_count < max_games:
                can_play = True
            else:
                # At limit but not in an active cooldown (e.g. cooldown ended or DB inconsistency);
                # allow starting a session so /game/submit can reset and count this play.
                can_play = True
            
        status_list.append(schemas.GameStatusItem(
            game_type=gtype,
            play_count=play_count,
            max_games=max_games,
            cooldown_until=cooldown_until,
            can_play=can_play,
            reward=config.get("reward")
        ))
        
    return schemas.GameStatusResponse(games=status_list)

@router.get("/leaderboard/{game_type}", response_model=schemas.GameLeaderboardResponse)
async def get_game_leaderboard(
    game_type: str,
    limit: int = 100,
    db: AsyncSession = Depends(database.get_db),
):
    """Get the highest scores for a specific game across all users."""
    limit = max(1, min(limit, _GAME_LB_LIMIT_CAP))

    # Subquery to find MAX score per user for this game
    # This prevents one user from taking multiple spots with different sessions
    subquery = (
        select(
            models.GameSession.user_id,
            func.max(models.GameSession.score).label("max_score")
        )
        .where(
            models.GameSession.game_type == game_type,
            models.GameSession.validated == True
        )
        .group_by(models.GameSession.user_id)
        .subquery()
    )
    
    # Join with User to get names/country
    query = (
        select(
            models.User.id,
            models.User.username,
            models.User.display_name,
            models.User.country,
            subquery.c.max_score
        )
        .join(subquery, models.User.id == subquery.c.user_id)
        .order_by(subquery.c.max_score.desc())
        .limit(limit)
    )
    
    result = await db.execute(query)
    rows = result.all()
    
    leaders = []
    for idx, row in enumerate(rows):
        leaders.append(schemas.GameLeaderboardEntry(
            rank=idx + 1,
            id=row.id,
            username=_mask_username(row.username),
            display_name=row.display_name,
            country=row.country,
            score=row.max_score
        ))
        
    return schemas.GameLeaderboardResponse(
        game_type=game_type,
        leaders=leaders
    )
