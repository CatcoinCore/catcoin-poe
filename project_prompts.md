# Catcoin PoE - Project Recreation Prompts

This document contains a series of detailed prompts to rebuild the Catcoin PoE application from scratch. Follow these steps sequentially to ensure a clean, robust, and bug-free implementation.

## Phase 1: Backend Foundation (FastAPI & Database)

**Prompt 1: Project Setup & Database**
> Create a new FastAPI project structure for "Catcoin PoE Backend".
> 
> **Requirements:**
> 1.  **Tech Stack:** Python 3.10+, FastAPI, SQLAlchemy (Async), Pydantic v2, PostgreSQL.
> 2.  **Database:** Use PostgreSQL. Define a `Base` model using SQLAlchemy's declarative base.
> 3.  **Models:** Create the following models with **UUID primary keys** (stored as Strings or native UUIDs):
>     *   `User`: id (UUID), username, hashed_password, referral_code, created_at.
>     *   `Wallet`: id (UUID), user_id (FK), catcoin_address, is_primary.
>     *   `Mission`: id (UUID), code (unique string), type (enum), reward_amount.
>     *   `MiningSession`: id (UUID), user_id (FK), start_time, end_time, status (ACTIVE/COMPLETED).
> 4.  **Configuration:** Create a `config.py` using `pydantic-settings` to manage environment variables (DB URL, Secret Key).
> 5.  **Output:** Provide the file structure, `requirements.txt`, `main.py`, `database.py`, `models.py`, and `config.py`.

**Prompt 2: Authentication System**
> Implement a robust JWT-based authentication system.
> 
> **Requirements:**
> 1.  **Security:** Use `passlib` for password hashing (bcrypt).
> 2.  **Tokens:** Use `python-jose` for JWT generation and verification.
> 3.  **Endpoints:**
>     *   `POST /auth/signup`: Register new user, generate unique referral code.
>     *   `POST /auth/login`: Authenticate and return Access Token.
> 4.  **Dependency:** Create a `get_current_user` dependency to protect routes.
> 5.  **Output:** `auth.py` (utils), `routers/auth.py`, and updated `main.py`.

## Phase 2: Core Business Logic

**Prompt 3: Mining Logic & Session Management**
> Implement the core mining logic with the following rules:
> 
> **Rules:**
> 1.  **Sessions:** A user can start a mining session (e.g., 4 hours).
> 2.  **Validation:** Users cannot start a new session if one is already active.
> 3.  **Referrals:** Users get a speed boost for every active referral.
> 4.  **Endpoints:**
>     *   `POST /mining/start`: Validates eligibility and creates a `MiningSession`.
>     *   `GET /stats/me`: Returns current mining status, hashrate, balance, and active session details.
> 5.  **Architecture:** Create a `MiningService` class to encapsulate this logic, keeping the router clean.
> 6.  **Output:** `services/mining.py`, `routers/mining.py`, and updated schemas.

**Prompt 4: Missions & Payouts**
> Add support for Missions (Ads) and Wallet Payouts.
> 
> **Requirements:**
> 1.  **Missions:** Users complete missions (e.g., "Watch Ad") to earn rewards or extend mining time.
>     *   `POST /missions/complete`: Validates mission code and awards reward.
> 2.  **Wallets:** Users can link CAT coin wallet addresses.
>     *   `POST /wallets`: Add a new wallet.
>     *   `GET /wallets`: List user wallets.
> 3.  **Payouts:** (Mock implementation for now)
>     *   `GET /payouts`: List historical payouts.
> 4.  **Output:** `routers/missions.py`, `routers/wallets.py`, and updated models/schemas.

## Phase 3: Frontend Foundation (Flutter)

**Prompt 5: Flutter Project & Architecture Setup**
> Create a new Flutter project "catcoin_poe_app".
> 
> **Architecture:**
> 1.  **State Management:** Use `Provider` (MultiProvider at root).
> 2.  **Networking:** Use `http` package with a dedicated `ApiService` class.
> 3.  **Logging:** Create a `LoggerService` wrapper around `dart:developer` for consistent logging.
> 4.  **Models:** Create Dart models that **exactly match** the backend Pydantic models (especially UUIDs as Strings).
>     *   `User`, `Wallet`, `MiningSession`, `Stats`.
> 5.  **Output:** `pubspec.yaml`, `lib/main.dart`, `lib/services/api_service.dart`, `lib/services/logger_service.dart`, and `lib/models/*.dart`.

**Prompt 6: Authentication & Providers**
> Implement the Authentication flow in Flutter.
> 
> **Requirements:**
> 1.  **AuthProvider:** Manages login state, token storage (use `flutter_secure_storage`), and user profile.
> 2.  **Screens:**
>     *   `LoginScreen`: Username/Password form.
>     *   `SignupScreen`: Registration form.
>     *   `AuthWrapper`: Widget to decide whether to show Login or Home screen based on token presence.
> 3.  **Output:** `lib/providers/auth_provider.dart`, `lib/screens/login_screen.dart`, `lib/screens/signup_screen.dart`, `lib/screens/auth_wrapper.dart`.

## Phase 4: Frontend UI & Integration

**Prompt 7: Mining Dashboard & Logic**
> Build the main `DashboardScreen` and `MiningProvider`.
> 
> **Requirements:**
> 1.  **MiningProvider:**
>     *   Fetches `CurrentStats` from backend.
>     *   Handles `startMining` calls.
>     *   Manages a local `Timer` for the countdown UI (synced with backend `expires_at`).
> 2.  **Dashboard UI:**
>     *   Show current balance, hashrate, and mining animation.
>     *   "Start Mining" button (disabled if active).
>     *   Countdown timer.
> 3.  **Integration:** Connect `MiningProvider` to `ApiService`.
> 4.  **Output:** `lib/providers/mining_provider.dart`, `lib/screens/dashboard_screen.dart`.

**Prompt 8: Wallet & Referrals**
> Implement the Wallet management and Referral screens.
> 
> **Requirements:**
> 1.  **WalletScreen:** List wallets, add new wallet form.
> 2.  **ReferralScreen:** Show my referral code, list of referred users, and active boosts.
> 3.  **Providers:** Update `MiningProvider` or create `WalletProvider` to handle these data fetches.
> 4.  **Output:** `lib/screens/wallet_screen.dart`, `lib/screens/referral_screen.dart`, and updated providers.

# Catcoin PoE - Project Recreation Prompts

This document contains a series of detailed prompts to rebuild the Catcoin PoE application from scratch. Follow these steps sequentially to ensure a clean, robust, and bug-free implementation.

## Phase 1: Backend Foundation (FastAPI & Database)

**Prompt 1: Project Setup & Database**
> Create a new FastAPI project structure for "Catcoin PoE Backend".
> 
> **Requirements:**
> 1.  **Tech Stack:** Python 3.10+, FastAPI, SQLAlchemy (Async), Pydantic v2, PostgreSQL.
> 2.  **Database:** Use PostgreSQL. Define a `Base` model using SQLAlchemy's declarative base.
> 3.  **Models:** Create the following models with **UUID primary keys** (stored as Strings or native UUIDs):
>     *   `User`: id (UUID), username, hashed_password, referral_code, created_at.
>     *   `Wallet`: id (UUID), user_id (FK), catcoin_address, is_primary.
>     *   `Mission`: id (UUID), code (unique string), type (enum), reward_amount.
>     *   `MiningSession`: id (UUID), user_id (FK), start_time, end_time, status (ACTIVE/COMPLETED).
> 4.  **Configuration:** Create a `config.py` using `pydantic-settings` to manage environment variables (DB URL, Secret Key).
> 5.  **Output:** Provide the file structure, `requirements.txt`, `main.py`, `database.py`, `models.py`, and `config.py`.

**Prompt 2: Authentication System**
> Implement a robust JWT-based authentication system.
> 
> **Requirements:**
> 1.  **Security:** Use `passlib` for password hashing (bcrypt).
> 2.  **Tokens:** Use `python-jose` for JWT generation and verification.
> 3.  **Endpoints:**
>     *   `POST /auth/signup`: Register new user, generate unique referral code.
>     *   `POST /auth/login`: Authenticate and return Access Token.
> 4.  **Dependency:** Create a `get_current_user` dependency to protect routes.
> 5.  **Output:** `auth.py` (utils), `routers/auth.py`, and updated `main.py`.

## Phase 2: Core Business Logic

**Prompt 3: Mining Logic & Session Management**
> Implement the core mining logic with the following rules:
> 
> **Rules:**
> 1.  **Sessions:** A user can start a mining session (e.g., 4 hours).
> 2.  **Validation:** Users cannot start a new session if one is already active.
> 3.  **Referrals:** Users get a speed boost for every active referral.
> 4.  **Endpoints:**
>     *   `POST /mining/start`: Validates eligibility and creates a `MiningSession`.
>     *   `GET /stats/me`: Returns current mining status, hashrate, balance, and active session details.
> 5.  **Architecture:** Create a `MiningService` class to encapsulate this logic, keeping the router clean.
> 6.  **Output:** `services/mining.py`, `routers/mining.py`, and updated schemas.

**Prompt 4: Missions & Payouts**
> Add support for Missions (Ads) and Wallet Payouts.
> 
> **Requirements:**
> 1.  **Missions:** Users complete missions (e.g., "Watch Ad") to earn rewards or extend mining time.
>     *   `POST /missions/complete`: Validates mission code and awards reward.
> 2.  **Wallets:** Users can link CAT coin wallet addresses.
>     *   `POST /wallets`: Add a new wallet.
>     *   `GET /wallets`: List user wallets.
> 3.  **Payouts:** (Mock implementation for now)
>     *   `GET /payouts`: List historical payouts.
> 4.  **Output:** `routers/missions.py`, `routers/wallets.py`, and updated models/schemas.

## Phase 3: Frontend Foundation (Flutter)

**Prompt 5: Flutter Project & Architecture Setup**
> Create a new Flutter project "catcoin_poe_app".
> 
> **Architecture:**
> 1.  **State Management:** Use `Provider` (MultiProvider at root).
> 2.  **Networking:** Use `http` package with a dedicated `ApiService` class.
> 3.  **Logging:** Create a `LoggerService` wrapper around `dart:developer` for consistent logging.
> 4.  **Models:** Create Dart models that **exactly match** the backend Pydantic models (especially UUIDs as Strings).
>     *   `User`, `Wallet`, `MiningSession`, `Stats`.
> 5.  **Output:** `pubspec.yaml`, `lib/main.dart`, `lib/services/api_service.dart`, `lib/services/logger_service.dart`, and `lib/models/*.dart`.

**Prompt 6: Authentication & Providers**
> Implement the Authentication flow in Flutter.
> 
> **Requirements:**
> 1.  **AuthProvider:** Manages login state, token storage (use `flutter_secure_storage`), and user profile.
> 2.  **Screens:**
>     *   `LoginScreen`: Username/Password form.
>     *   `SignupScreen`: Registration form.
>     *   `AuthWrapper`: Widget to decide whether to show Login or Home screen based on token presence.
> 3.  **Output:** `lib/providers/auth_provider.dart`, `lib/screens/login_screen.dart`, `lib/screens/signup_screen.dart`, `lib/screens/auth_wrapper.dart`.

## Phase 4: Frontend UI & Integration

**Prompt 7: Mining Dashboard & Logic**
> Build the main `DashboardScreen` and `MiningProvider`.
> 
> **Requirements:**
> 1.  **MiningProvider:**
>     *   Fetches `CurrentStats` from backend.
>     *   Handles `startMining` calls.
>     *   Manages a local `Timer` for the countdown UI (synced with backend `expires_at`).
> 2.  **Dashboard UI:**
>     *   Show current balance, hashrate, and mining animation.
>     *   "Start Mining" button (disabled if active).
>     *   Countdown timer.
> 3.  **Integration:** Connect `MiningProvider` to `ApiService`.
> 4.  **Output:** `lib/providers/mining_provider.dart`, `lib/screens/dashboard_screen.dart`.

**Prompt 8: Wallet & Referrals**
> Implement the Wallet management and Referral screens.
> 
> **Requirements:**
> 1.  **WalletScreen:** List wallets, add new wallet form.
> 2.  **ReferralScreen:** Show my referral code, list of referred users, and active boosts.
> 3.  **Providers:** Update `MiningProvider` or create `WalletProvider` to handle these data fetches.
> 4.  **Output:** `lib/screens/wallet_screen.dart`, `lib/screens/referral_screen.dart`, and updated providers.

## Phase 5: Final Polish

**Prompt 9: Error Handling & Polish**
> Finalize the application with robust error handling.
> 
> **Checklist:**
> 1.  **Global Error Handling:** Ensure `ApiService` catches non-200 responses and throws clear exceptions.
> 2.  **UI Feedback:** Show `Snackbars` for errors (e.g., "Login failed", "Mining failed to start").
> 3.  **Loading States:** Ensure all buttons show loading spinners while async operations are in progress.
> 4.  **Review:** Double-check that all Frontend Models use `String` for IDs to match Backend UUIDs.

---

## ADDON PROMPTS: Advanced Features

### Prompt 10: Multi-Session Mining Architecture
> Upgrade the mining system to support **multiple simultaneous sessions**.
>
> **Backend Requirements:**
> 1.  **Session Types:**
>     *   `BASE`: User mines for themselves (one per user).
>     *   `REFERRAL_BOOST`: User mines for an active referral (multiple allowed).
> 2.  **Database:**
>     *   Add `session_type` (enum) and `mining_for` (UUID FK) to `MiningSession`.
>     *   Add `active_session_ids` (JSON array) to `User` for fast lookup.
> 3.  **Service Logic (`SessionManager`):**
>     *   `create_base_session(user)`: Creates the main mining session.
>     *   `create_referral_boost_session(user, referral_id)`: User boosts a referral's mining.
>     *   `calculate_combined_hashrate(user)`: Sum hashrates from all active sessions.
>     *   `checkpoint_all_sessions(user)`: Update earnings for all sessions periodically.
> 4.  **API Updates:**
>     *   `POST /mining/boost/{referral_id}`: Start a boost session for a referral.
>     *   `GET /stats/me`: Return `active_sessions` array with details (session_id, type, mining_for, hashrate, expires_at, total_earned).
> 5.  **Rules:**
>     *   Users can only boost **active referrals** (last_active < 24h).
>     *   Each referral can only be boosted **once** per user.
>     *   Sessions auto-close when `end_time` is reached.
>
> **Frontend Requirements:**
> 1.  **Models:** Create `ActiveSession` and `ReferralBoostInfo` models.
> 2.  **Dashboard:** Display all active sessions with individual timers and earnings.
> 3.  **Referral Boost Screen:**
>     *   List all referrals with "Boost" button (disabled if already boosted or inactive).
>     *   Show active boost sessions with countdown and earnings.

### Prompt 11: Earnings Ledger & Reward System
> Implement a comprehensive **Earnings Ledger** to track all rewards.
>
> **Backend Requirements:**
> 1.  **EarningsLedger Model:**
>     *   `id`, `user_id`, `amount`, `reward_type` (enum: MINING_BASE, MINING_REFERRAL_BOOST, SOCIAL_FACEBOOK, AIRDROP, etc.).
>     *   `is_verified` (bool): True after payout.
>     *   `created_at`, `payout_id` (FK, nullable).
> 2.  **Reward Types Enum:**
>     *   Mining: `MINING_BASE`, `MINING_REFERRAL_BOOST`.
>     *   Social: `SOCIAL_FACEBOOK`, `SOCIAL_X`, `SOCIAL_DISCORD`, `SOCIAL_TELEGRAM`.
>     *   Other: `MISSION_COMPLETION`, `REFERRAL_SIGNUP_BONUS`, `AIRDROP`.
> 3.  **Service Logic:**
>     *   `append_earnings(user, amount, reward_type)`: Add ledger entry.
>     *   `calculate_earnings_breakdown(user)`: Return dict of total per reward_type.
> 4.  **API Integration:**
>     *   Update `/stats/me` to include:
>         - `earnings_breakdown`: `{"MINING_BASE": 0.05, "SOCIAL_X": 0.01, ...}`
>         - `total_verified_earnings`, `total_unverified_earnings`.
>
> **Frontend Requirements:**
> 1.  **Dashboard:** Display earnings breakdown as a chart or list.
> 2.  **Stats Model:** Add `earningsBreakdown`, `totalVerifiedEarnings`, `totalUnverifiedEarnings` fields.

### Prompt 12: Admin Panel & Configuration System
> Create an **Admin Panel** to manage application parameters dynamically.
>
> **Backend Requirements:**
> 1.  **AdminConfig Model:**
>     *   `ad_required_for_mining_start` (bool)
>     *   `ad_required_for_speed_boost` (bool)
>     *   `ad_required_for_time_boost` (bool)
>     *   `time_boost_duration_seconds` (int, default 14400 = 4h)
>     *   `speed_boost_per_referral` (float, default 10.0)
>     *   Store as a **singleton row** in the database.
> 2.  **Endpoints:**
>     *   `GET /v1/config/`: Public endpoint, returns current config.
>     *   `PUT /v1/admin/config`: Protected (admin-only), updates config.
> 3.  **Integration:** Use these values in `SessionManager` to determine hashrate and duration.
>
> **Frontend Requirements:**
> 1.  **AdminScreen:** Form to edit all config values.
>     *   Only visible to admin users (check `username == "root"` or add `is_admin` field).
> 2.  **AppConfig Model:** Dart model with `fromJson` and `toJson`.
> 3.  **Provider Integration:** Fetch config on app startup in `MiningProvider`.

### Prompt 13: Hashrate Multipliers & Bonuses
> Implement **dynamic hashrate calculation** based on referrals and bonuses.
>
> **Backend Formula:**
> ```python
> base_hashrate = 100.0
> referral_count = len([r for r in user.referrals if r.is_active])
> speed_boost_per_referral = admin_config.speed_boost_per_referral  # e.g., 10.0
> 
> total_hashrate = base_hashrate + (referral_count * speed_boost_per_referral)
> ```
>
> **Features:**
> 1.  **Referral Boost:** Each **active** referral adds 10% (or configurable) to hashrate.
> 2.  **Speed Boost Missions:** Optional missions that temporarily double hashrate (store in user session metadata).
> 3.  **Time Bonus:** Missions that extend session duration by 4 hours (configurable).
>
> **Frontend:**
> 1.  **Dashboard:** Display current hashrate prominently (e.g., "250 H/s").
> 2.  **Bonus Cards:** Show available bonuses ("Extend Mining +4h", "Speed Boost x2") with "Watch Ad" buttons.

### Prompt 14: Tri-Color Ring Animation & Logo
> Add visual polish to the Dashboard with an **animated tri-color ring** and **logo**.
>
> **Frontend Requirements:**
> 1.  **Tri-Color Ring:**
>     *   Use `CustomPaint` widget to draw 3 arcs (120° each) in different colors (e.g., gold, silver, bronze).
>     *   Animate rotation using `AnimationController` (continuous rotation when mining).
>     *   Place the ring around the coin balance or in the center of the dashboard.
> 2.  **Logo:**
>     *   Create or use a simple "CAT" coin logo (circular icon with "CAT" text).
>     *   Display in AppBar and Dashboard center.
> 3.  **Mining Animation:**
>     *   Add a pulsing effect or glow to the ring when mining is active.
>     *   Optional: Animate coins floating upward behind the ring.
>
> **Implementation Tip:**
> ```dart
> CustomPaint(
>   painter: TriColorRingPainter(rotationAngle: _controller.value),
>   child: Center(child: Text('\$balance CAT')),
> )
> ```

### Prompt 15: Referral Tracking & Activity Status
> Enhance the referral system with **activity tracking**.
>
> **Backend Requirements:**
> 1.  **User Model:**
>     *   Add `last_active_at` (timestamp, updated on every API call).
>     *   Add `is_active` (computed: `last_active_at < 24 hours ago`).
> 2.  **Middleware:** Update `last_active_at` for authenticated users on every request.
> 3.  **API Updates:**
>     *   `/stats/me` returns `available_referrals` array:
>         - `referral_id`, `referral_username`, `is_active`, `last_active_at`.
>         - `can_boost`: False if already boosted or inactive.
>         - `active_boost_session_id`: If currently boosting this referral.
>
> **Frontend Requirements:**
> 1.  **ReferralScreen:**
>     *   Display referrals in a list with "Active" or "Inactive" badge.
>     *   Show "Last active: 2 hours ago" timestamp.
> 2.  **ReferralBoostScreen:**
>     *   Only show "Boost" button for active referrals.
>     *   Disable button if already boosted.

### Prompt 16: Payout History & Wallet Verification
> Implement **Payout History** and **Wallet Verification** features.
>
> **Backend Requirements:**
> 1.  **Payout Model:**
>     *   `id`, `user_id`, `catcoin_address`, `amount_cat`, `txid` (blockchain transaction ID).
>     *   `status`: "pending", "sent", "failed".
>     *   `created_at`, `sent_at`.
> 2.  **Endpoints:**
>     *   `GET /v1/payouts/`: List user's payout history.
>     *   `POST /v1/wallets/verify/{wallet_id}`: Mock verification (set `verified_at`).
> 3.  **Auto-Payout Logic (Optional):**
>     *   Cron job that creates payouts when `total_verified_earnings >= 0.1 CAT`.
>
> **Frontend Requirements:**
> 1.  **PayoutHistoryScreen:**
>     *   List all payouts with date, amount, status, and TXID.
>     *   Use colored chips for status (green = sent, orange = pending).
> 2.  **WalletScreen:**
>     *   Show "Verified" badge for verified wallets.
>     *   Add "Verify" button (calls mock verification endpoint).

---

## Final Checklist

Before launching, ensure:
- [ ] All UUIDs are stored and transmitted as **Strings**.
- [ ] All API responses include proper error messages.
- [ ] Frontend models match backend schemas **exactly**.
- [ ] Logging is comprehensive (LoggerService in Flutter, logger in FastAPI).
- [ ] Admin panel is secured (only accessible to `is_admin` users).
- [ ] Tri-color ring animation runs smoothly (60fps).
- [ ] Test with multiple referrals and simultaneous sessions.
