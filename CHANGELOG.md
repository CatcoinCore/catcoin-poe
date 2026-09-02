# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.12.0] - 2026-09-02
### Changed
- Android R8 **full mode** + **class repackaging** (`-repackageclasses`, `-allowaccessmodification`) per Play Console optimization tips — smaller DEX, stronger obfuscation; verified with an Android 16 runtime smoke test.
- Minor version bump for store submission; in-app **What's New** seed updated for all locales; Fastlane `110` changelog.

## [1.11.0] - 2026-07-28
### Changed
- Target **Android 16 (API level 36)** for Google Play compliance; `compileSdk`/`targetSdk` 35 → 36 (verified via release AAB build).
- Minor version bump for store submission; in-app **What's New** seed updated for all locales; Fastlane `109` changelog.

## [1.10.10] - 2026-05-09
### Changed
- Patch release; version bump for store submission.
- In-app **What's New** seed updated for all locales; Fastlane `108` changelog; Play listing draft aligned.

## [1.10.9] - 2026-05-09
### Changed
- Patch release; version bump for store submission.
- In-app **What's New** seed (`default_whats_new.json`) updated for all locales; Fastlane `107` changelog; `play_store_description` release notes draft aligned.

## [1.10.8] - 2026-05-06
### Changed
- Patch release; version bump for store submission.

## [1.10.7] - 2026-04-24
### Changed
- Patch release; version bump for store submission.

## [1.10.6] - 2026-04-23
### Changed
- Patch release; version bump for store submission.

## [1.10.5] - 2026-04-22
### Changed
- Patch release; version bump for store submission.

## [1.10.4] - 2026-04-21
### Changed
- Patch release; version bump for store submission.

## [1.10.3] - 2026-04-20
### Changed
- Patch release; version bump for store submission.

## [1.10.2] - 2026-04-20
### Added
- **Tunnel Miner** mini-game (Flame): vertical descent, hazards, score submission as `MINER`, integrated with games tab and session gating.
- Referral **milestone** and **signup** bonuses, invite redirect hardening, pending referral storage, and referral bonus detail UI.
### Changed
- Backend: referral bonus services and routers, admin config compatibility, session manager updates; Alembic migration for referral milestone bonus.
### Fixed
- Games eligibility and session gate tests aligned with `MINER` and invite flows.

## [1.9.7] - 2026-04-07
### Added
- Awards and badges: richer badge metadata (period, rank, scope, region, game type) and Awards screen sections for global, regional, and per-game leaders.
### Changed
- Leaderboard screen refinements; Runner and mini-game flow updates; expanded localization strings.
### Fixed
- Minor Android theme/style cleanup.

## [1.9.6] - 2026-04-07
### Fixed
- Android: startup crash from unsupported operations in `MainActivity`.
### Changed
- Game cooldown UX and rewarded-ad gating for post-game rewards.

## [1.9.5] - 2026-04-06
### Changed
- Boosters card badge counts time boosts, referral boosts, and unused game-boost inventory (game boosts shown even when not mining).
- Rewarded ads: if AdMob returns no fill (code 3) on on-demand load, grant the reward automatically; failed show no longer grants a reward.
### Fixed
- Clearer ad load/show logging for pre-load vs on-demand paths.
### Backend
- Alembic revision formatting and deployment packaging updates (`create_deployment_package`, `mirror_deploy`, production Docker Compose).

## [1.9.4] - 2026-04-05
### Fixed
- Games tab badge/count now matches the visible list of eligible games.
- Sudoku pencil mode: candidate filtering, note cleanup, and note highlighting behavior.
### Changed
- Updated `firebase_core`, `app_links`, and refreshed `pubspec.lock`.

## [1.9.3] - 2026-04-04
### Changed
- Dashboard loads balance details lazily for snappier startup and smoother scrolling.
- Boosters screen streamlined for clearer time-boost presentation.
- Mini-games use shared session gating helpers for consistent entry checks.
### Fixed
- Mining provider and admin config model aligned with current backend fields.

## [1.9.2] - 2026-04-03
### Added
- Mining Activation Overlay: full-screen blur blocks all dashboard interactions until mining starts.
- Global Navigation Lock: bottom navigation bar is disabled until a mining session is active; auto-redirects to dashboard if session expires on another tab.
- Unclaimed missions badge: Rewards tab now shows the correct count of claimable missions.
- Game Leaderboard Access: Trophy icon on each game card navigates directly to that game's leaderboard.
- Game-specific color themes in the Leaderboard "Games" tab (Runner: Orange, TicTacToe: Blue, Sudoku: Purple, Collage: Green).
### Fixed
- Backend: `game_reward_config` column missing from `admin_config` database; migration script added to `run_all_migrations.py`.
- `update_game_rewards_schema.py`: Fixed broken import (`engine` → `async_engine`).
- `create_deployment_package.py`: Added all missing migration scripts so future deploys are complete.
- `dashboard_screen.dart`: Fixed malformed Stack widget structure and missing `dashboardWelcome` localization key.
- `leaderboard_screen.dart`: `LeaderboardScreen` now accepts `initialIndex` and `initialGameType` for deep-linking.

## [1.9.1] - 2026-04-03
### Changed
- Enhanced Sudoku with haptic feedback for incorrect numbers and notes.
- Updated Sudoku "Pencil Mode" to no longer count incorrect notes as game-over mistakes.
- Standardized Sudoku UI accent colors to Orange for better theme consistency.
- Cleaned up Sudoku header UI for a more immersive gameplay experience.
- Updated Android `androidx.activity` dependencies to version 1.9.0.

## [1.9.0] - 2026-04-03
### Added
- Major upgrade to Admin Mission management and configuration tools.
- Integrated background task processing for optimized startup synchronization.
### Changed
- Comprehensive UI/UX refinements across mini-games and localization files.
- Enhanced backend stability with resilient health checks and automated migrations.
### Fixed
- Fixed Game Boost yield calculation and administrative router import errors.

## [1.8.9] - 2026-04-02
### Fixed
- Fixed Game Boost yield calculation to correctly reflect active boosts in the reward rate.
- Added proactive database enum migrations on startup for improved stability.
- Increased deployment health check resilience and timeouts to prevent rollback failures.
- Resolved `NameError` and missing import issues in administrative and authentication routers.
- Optimized startup user synchronization with background task processing.

## [1.8.8] - 2026-04-02
### Added
- Implemented Special Bonus tracking category in balance breakdown.
- Added Earnings History filtering by reward type for better transparency.
- Major upgrade to Admin User Management with robust pagination and multi-parameter filtering.
### Fixed
- Fixed critical build errors and resolved all performance warnings in the Flutter app.

## [1.8.7] - 2026-04-02
### Changed
- Improved TicTacToe CPU AI with strategic winning and blocking moves.
- Refactored mini-game interfaces (TicTacToe, Sudoku, Collage) to dynamically use system theme colors.
- Updated TicTacToe turn logic to alternate between user and CPU for a fairer experience.
### Fixed
- Fixed backend configuration processing to correctly persist `game_ads_enabled` updates.

## [1.8.6] - 2026-04-02
### Added
- Integrated AdMob Interstitial ads into all mini-games.
- Added preloading logic for game transitions in AdService.
- Respect "Enable Game Ads" administrative toggle for gameplay sessions.

## [1.8.5] - 2026-04-02
### Added
- Added Firebase core to Android & iOS builds.
- Refined Admin AdMob toggles and backend routing logic.
- Included Sudoku and Collage visibility controls backend support.
### Fixed
- Fixed 500 Internal Server error preventing mini-game launches.

## [1.8.4] - 2026-04-02
### Added
- Integrated Firebase core and Google Services for analytics/ads.
- Added Admin Ads screen configuration.
- Sync work on l10n, dashboards, versions and new scripts.
### Fixed
- Fixed backend plugin registrations.

## [1.8.3] - 2026-04-02
### Added
- Sync work on mini-games, deep linking, and l10n.
- Enhance runner game, add localization.
- Update UI/UX and versioning adjustments.
### Fixed
- Fixed localization and general game interface stability.

## [1.8.1] - 2026-04-01
### Added
- Additional game system refinements.
- Improved app launch stability and performance.
### Fixed
- General stability fixes and minor bug corrections.

## [1.8.0] - 2026-04-01
### Added
- Major game engine updates for a smoother gaming experience.
- Improved app launch stability and performance.
### Fixed
- General stability fixes and minor bug corrections.

## [1.7.9] - 2026-04-01
### Added
- Performance optimizations for game sessions.
- Memory management improvements.
### Fixed
- General UI refinements and minor bug corrections.

## [1.7.8] - 2026-04-01
### Added
- Additional game system refinements.
- Improved app launch stability and performance.
### Fixed
- General stability fixes and minor bug corrections.

## [1.7.7] - 2026-04-01
### Added
- Performance optimizations for game sessions.
- Memory management improvements.
### Fixed
- General UI refinements and minor bug corrections.

## [1.7.6] - 2026-04-01
### Added
- Additional game system refinements.
- Improved app launch stability and performance.
### Fixed
- General stability fixes and minor bug corrections.

## [1.7.5] - 2026-04-01
### Added
- Additional game engine optimizations.
- Improved app launch stability and performance.
### Fixed
- General stability fixes and minor bug corrections.

## [1.7.4] - 2026-04-01
### Added
- Additional game system refinements.
- Improved app launch stability and performance.
### Fixed
- General stability fixes and minor bug corrections.

## [1.7.3] - 2026-04-01
### Added
- Performance optimizations for game sessions.
- Memory management improvements.
### Fixed
- General UI refinements and minor bug corrections.

## [1.7.2] - 2026-04-01
### Added
- Additional game engine optimizations.
- Improved app launch stability and memory management.
### Fixed
- General stability fixes and minor bug corrections.

## [1.7.1] - 2026-04-01
### Added
- Additional game system refinements.
- Improved app launch stability and performance.
### Fixed
- General stability fixes and minor bug corrections.

## [1.7.0] - 2026-04-01
### Added
- Major game engine updates for a smoother gaming experience.
- Improved app launch stability and performance.
### Fixed
- General stability fixes and minor bug corrections.

## [1.6.9] - 2026-04-01
### Added
- Additional game system refinements.
- Improved app launch stability and performance.
### Fixed
- General stability fixes and minor bug corrections.

## [1.6.8] - 2026-04-01
### Added
- Performance optimizations for game sessions.
- Memory management improvements.
### Fixed
- General UI refinements and minor bug corrections.

## [1.6.7] - 2026-04-01
### Added
- Additional runner game optimizations.
- Improved app launch time and general performance.
### Fixed
- General stability fixes and minor bug corrections.

## [1.6.6] - 2026-04-01
### Added
- Additional performance optimizations.
- Improved app stability and memory usage.
### Fixed
- General UI refinements and minor bug corrections.

## [1.6.5] - 2026-04-01
### Added
- Additional runner game balancing.
- Improved app launch stability and performance.
### Fixed
- General stability fixes and minor bug corrections.

## [1.6.4] - 2026-04-01
### Added
- Performance optimizations for user dashboard.
- Memory management improvements.
### Fixed
- General UI refinements and minor bug corrections.

## [1.6.3] - 2026-04-01
### Added
- Additional runner game asset optimizations.
- General app stability and UI fixes.
### Fixed
- Improved backend synchronization.

## [1.6.2] - 2026-04-01
### Added
- Additional balancing for the runner game.
- Improved app performance and responsiveness.
### Fixed
- General stability fixes and minor UI corrections.
