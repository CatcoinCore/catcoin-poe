"""
Canonical defaults for admin_config JSON columns (game boosts / game rewards).

Used by:
- SessionManager when creating the singleton admin_config row (id=1)
- seed_admin_game_config.py for backfilling empty columns
- One-off migrations that add columns with a DB DEFAULT
- Tests

Admin edits persist in the database; this module is only for initial / missing values.
Do not duplicate these strings in routers, models, schemas, or the Flutter client.
"""

# Game boost matrix: percentage -> list of duration options (minutes)
DEFAULT_GAME_BOOST_CONFIG_JSON = (
    '{"20": [60, 120], "15": [60, 120, 180], "10": [60, 120, 180, 240], '
    '"5": [60, 120, 180, 240, 300, 360]}'
)

# Per-game fixed rewards, play caps, cooldown hours (RUNNER uses null reward = coin-based)
DEFAULT_GAME_REWARD_CONFIG_JSON = (
    '{"TICTACTOE": {"reward": 10, "max_games": 10, "cooldown_hours": 2}, '
    '"SUDOKU": {"reward": 100, "max_games": 10, "cooldown_hours": 3}, '
    '"COLLAGE": {"reward": 50, "max_games": 10, "cooldown_hours": 2}, '
    '"MINER": {"reward": 75, "max_games": 15, "cooldown_hours": 2}, '
    '"ARROW": {"reward": 30, "max_games": 10, "cooldown_hours": 2}, '
    '"TWENTY48": {"reward": 75, "max_games": 10, "cooldown_hours": 3}, '
    # Tile Swap (Flame): score-goal puzzle. Reward when the player reaches
    # the goal before moves run out (score-goal validation lives in
    # routers/game.py via MIN_TILE_SWAP_SCORE_FOR_REWARD).
    '"TILE_SWAP": {"reward": 25, "max_games": 10, "cooldown_hours": 2}, '
    '"RUNNER": {"reward": null, "max_games": null, "cooldown_hours": null}}'
)
