# Implementation Summary

## Tunnel Miner (CatCoin) — April 2026

### What was implemented

- **CatCoin Tunnel Miner** MVP: tile-based vertical descent, dig energy, ore shards, lava and falling boulders, extraction tile win, HUD / intro / pause / result overlays, Flame rendering without extra asset downloads.
- **Games tab integration** using the existing **MINER** visibility flag and reward card layout.
- **Shared workflow**: `ensureGamePlayAllowed` → `GameProvider.startSession()` → play → `submitScore(..., gameType: 'MINER')` → ads + `MiningProvider.fetchStats()` → optional boost dialog (same pattern as Runner).
- **Backend**: `MINER` entry in default `game_reward_config` (fixed catoshi reward + caps/cooldown); anti-cheat clamps for submitted **score** and **depth** vs session duration; clear **503** if live admin JSON omits `MINER`.

### Where it lives in the repo

- Flutter: `cat_poe/lib/games/tunnel_miner/` (`data/`, `game/`, `presentation/`).
- Entry: `cat_poe/lib/screens/games_screen.dart` → `TunnelMinerScreen`.
- Eligibility / gate: `cat_poe/lib/utils/games_screen_eligibility.dart`, `cat_poe/lib/utils/game_session_gate.dart`.
- Backend defaults: `cat_poe_backend/admin_config_defaults.py`; submit logic: `cat_poe_backend/routers/game.py`.
- Audit: `docs/tunnel_miner_current_state_audit.md`.

### Reused from Runner / existing game flow

- `GameProvider` + `GameService` session and submit.
- `GameWidget` overlay pattern, `GameScreenCaptureGuard`, reward boost UI helper, interstitial ad hook, mining stats refresh.

### Tests added / updated

- `cat_poe/test/tunnel_miner_score_test.dart` — score formula.
- `cat_poe/test/games_screen_eligibility_test.dart` — MINER playable counting and “all locked” includes MINER.

### Limitations / follow-ups

- **Missions**: still server-driven only; no new mission codes in the client.
- **Localization**: new strings are English in all ARB files for this pass (gen-l10n may report untranslated counts for non-English locales).
- **Balance**: reward numbers (`75` catoshi default, caps) are reasonable defaults but should be tuned with telemetry.
