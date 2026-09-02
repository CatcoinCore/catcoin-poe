# Tunnel Miner — Current App Audit (pre-integration baseline + integration map)

## Runner entry point

- **Games tab**: `lib/screens/games_screen.dart` → card opens `GameLauncherScreen` → `GameScreen` (`lib/games/runner/ui/game_launcher_screen.dart`, `game_screen.dart`).
- **Assets**: `RunnerAssetService` / `AssetPackService` gate first-run downloads before `GameScreen`.

## Existing game / reward workflow

1. **Gate (optional)**: `lib/utils/game_session_gate.dart` — `ensureGamePlayAllowed(context, gameType: …)` calls `GameProvider.fetchStatus()` and blocks if `canPlay` is false.
2. **Session start**: `GameProvider.startSession()` → `GameService.post('/game/start')` → stores `session_token`.
3. **Play**: Flame `RunnerGame` in `lib/games/runner/game/runner_game.dart`.
4. **Finish**: `RunnerGame` sets game over; `GameScreen` calls `submitScore(score, coinsCollected, distanceMeters, gameType: RUNNER)` (default).
5. **Reward UX**: optional boost dialog via `lib/utils/game_reward_feedback.dart`; interstitial `AdService`; `MiningProvider.fetchStats()`.

## Key screens / services / providers

| Area | Location |
|------|-----------|
| Game API | `lib/services/game_service.dart` — `/game/start`, `/game/submit`, `/game/status`, `/game/history`, `/game/leaderboard/{type}` |
| Game state | `lib/providers/game_provider.dart` — `startSession`, `submitScore(..., gameType)` |
| Games list | `lib/screens/games_screen.dart` + `lib/utils/games_screen_eligibility.dart` |
| Missions | `lib/services/mission_service.dart`, `lib/models/mission.dart` — server-driven `GET /missions/`, `POST /missions/complete` (no game-specific hooks in client today) |
| Admin visibility | `lib/models/admin_config.dart` — `isMinerGameVisible` already existed for the MINER row |

## Backend (this repo)

- `cat_poe_backend/routers/game.py` — shared `/game/start` (no game type on start), `/game/submit` uses `game_type` + `game_reward_config` JSON from `admin_config`.
- Defaults: `cat_poe_backend/admin_config_defaults.py` + `seed_admin_game_config.py` for empty DB columns.

## Reusable pieces for Tunnel Miner

- **Session + submit**: same `GameProvider` / `GameService` as Sudoku/TicTacToe; `submitScore` already accepts `gameType`.
- **Status / cooldowns**: `/game/status` entries keyed by `game_type` from `game_reward_config`.
- **Leaderboards**: existing `LeaderboardScreen(initialGameType: 'MINER')` from game card trophy icon.
- **Overlays + Flame**: same `GameWidget` + overlay pattern as `GameScreen` (Runner).

## Tunnel Miner integration points (implemented)

- **Game type string**: `MINER` (reuses reserved Games tab row and admin `is_miner_game_visible`).
- **Navigation**: `GamesScreen` → `TunnelMinerScreen` (`lib/games/tunnel_miner/presentation/tunnel_miner_screen.dart`).
- **Submit payload**: `score` = client formula; `coins_collected` = shard count (informational; fixed reward uses server config like other mini-games); `distance_meters` = max depth row index.
- **Backend**: `MINER` added to `DEFAULT_GAME_REWARD_CONFIG_JSON`; submit clamps score/depth vs session duration; rejects submit if `MINER` missing from live `game_reward_config`.

## What must stay unchanged

- Runner module, launcher, and asset pipeline.
- Existing `game_type` values for other games (`RUNNER`, `SUDOKU`, etc.).
- Shared `/game/start` contract (no breaking change to request body).

## Missions / profile / streaks

- **Missions** remain server-defined; no new client mission codes were added. Any “play MINER / reach depth X” missions require backend mission definitions + optional future client `completeMission` calls with verification payloads.
- **Profile / streaks**: unchanged; rewards flow through existing game reward ledger + balance update on `/game/submit`.

## Operational assumption

- Deployments with an existing `game_reward_config` must **add a `MINER` object** (or run `python cat_poe_backend/seed_admin_game_config.py` on empty columns). Otherwise `/game/submit` with `game_type: MINER` returns **503** with a clear message.
