# Walkthrough: Leaderboard Flags and Suspicious IP Detection Fixes

## Overview
This walkthrough summarizes the changes made to correct the incorrect country flags in the leaderboard and the overly sensitive suspicious IP detection.

## Changes Made
### 1. Leaderboard Country Code Resolution (Frontend)
- **Previous Behavior**: The app used the device's locale settings (e.g., "English (UK)") to detect country code, which resulted in displaying the UK flag for many users residing in other regions (e.g., India).
- **New Behavior**: The `_syncDeviceCountry` function in `auth_provider.dart` now fetches the physical location using the secure `https://get.geojs.io/v1/ip/country.json` endpoint. 
    - *Note:* The previous implementation attempted an `http` request which was blocked by iOS App Transport Security and Android's Cleartext Traffic prevention, causing it to fail silently and fall back to the incorrect Device Locale. Using an HTTPS API completely resolves this without requesting GPS Location Permissions (which would require Google Play App Policy updates).

### 2. IP Proxy Handling & Null ID Fixes (Backend)
- **Previous Behavior**: Connections routing through typical proxies recorded all incoming IP addresses as `127.0.0.1`. Furthermore, string literals parsed from mobile request headers like `"null"` or `"N/A"` caused SQL logic to cluster multiple users as matching the same IP or Device ID, triggering false positive `IP_FARMING` records.
- **New Behavior**: 
    - In `auth.py`, the `ip_address` extraction prioritizes the `CF-Connecting-IP` header (if using Cloudflare) before falling back to `X-Forwarded-For` and `X-Real-IP` to retrieve the absolute true user IP.
    - Updated the `login` endpoint in `auth.py` to re-capture and continually update the user's `ip_address` and `device_id` on every login, preventing users from being stuck with stale or invalid IP addresses collected during account creation.
    - In `fraud_detection.py`, strict sanitation ensures strings mimicking nulls evaluate to true Pythonese `None`, skipping fraud checks appropriately.
    - Added `fix_null_suspicious.py` appended to database migrations (`run_all_migrations.py`) which automatically scans and unmarks users whose logs are solely false positives stemming from `N/A` missing data.

### 3. Detailed Suspicious Logs (Backend)
- **Previous Behavior**: Suspicious logs generalized evidence as "IP address used by X accounts".
- **New Behavior**: In `fraud_detection.py`, the `MULTIPLE_ACCOUNTS_DEVICE` and `IP_FARMING` events insert the exact logged IP Address and Device ID directly into the evidence string so the admin knows precisely which address was flagged.

### 4. Admin Manual Unmark Suspicious Flow (Frontend & Backend)
- Added a `POST /admin/users/{user_id}/unmark-suspicious` API in `admin.py` to reset the `is_suspicious` flag from true to false.
- Embedded an **"Unmark as Suspicious"** row inside the admin panel `PopupMenuButton` in `admin_users_screen.dart`.
- **UI Enhancement**: Added a prominent **"Unmark as Safe"** button directly inside the Suspicious Evidence Log dialog, making it much easier to unmark users without using the dropdown menu.
- **UI Enhancement**: The user's IP Address is now natively displayed in the subtitle of the Admin User card for immediate visibility into potentially duplicated IPs.
- **UI Enhancement**: Added a **"User Matching Data"** context block at the top of the Suspicious Activity Log dialog. It permanently displays the user's exact IP Address, Device ID, and all connected Social IDs, explicitly giving the admin the exact values matching other suspicious accounts.

### 5. Add/Edit Referral Code Post-Signup
- **Backend API**: Added a new schema `UpdateReferredByRequest` and `POST /auth/users/me/referred-by` endpoint to allow users to update their inviter code. Validates that the referral code exists and prevents self-referrals.
- **Frontend UI**: Built an **"Invited By"** context card in the `ReferralScreen` above the standard referral card. Users can click **Edit** (or Add) to invoke an input dialog to connect their account to a friend's referral code.
- **Dynamic Integration**: When the code is successfully saved, the local user profile is dynamically re-fetched alongside the system mining statistics to instantly apply all referral boost recalculations without requiring an app restart.

### 6. Referral Code Case Sensitivity Mismatch
- **Previous Behavior**: The `SignupScreen` automatically submitted referral codes in ALL CAPS regardless of input (e.g. `A1B2C3D4`) due to the `textCapitalization` modifier. Meanwhile, the backend generated referral codes via `uuid4()` uniformly producing lowercase (`a1b2c3d4`). Due to strict case-sensitivity in PostgreSQL, the `referred_by == referral_code` SQL equivalence completely failed for returning referred users natively—even though the referred user saw the uppercase string in their profile.
- **New Behavior**: Modifies the `signup` and `update_referred_by` endpoints in the backend to systematically enforce `.strip().lower()` parsing before saving to PostgreSQL.
- **Database Cleanup:** Written and appended `fix_referral_case.py` into the `run_all_migrations.py` pipeline, which scans the DB and permanently updates all existing corrupted uppercase referrals to lowercase so older referral chains instantaneously reappear on referrers' screens!

### 7. Enforcing "Active" Status for Referrals
- **Previous Behavior**: A referred user was considered "Active" (granting their referrer a multiplier boost) if `last_active_at` was within 24 hours. However, simply logging into the app updated `last_active_at`, meaning users who logged in but never pushed "Start Mining" still granted full boosts.
- **New Behavior**: Removed `last_active_at` tracking from the `login` and `verify_email` authentication endpoints. Re-injected user activity updates specifically inside the `create_base_session` and `extend_session` methods. Therefore, an invited user must *actually be mining* to continually update their activity timestamp and reward their referrer.

### 8. Dark Mode Accessibility Scrubber
- **Leaderboard Legibility**:
  - Removed static `Colors.white` background assertions inside the `LeaderboardScreen` custom cards so that the leaderboard dynamically adapts to dark mode (`Theme.of(context).cardColor`).
  - Switched the leaderboard text values strictly tracking the top-3 placements to dynamically select `Colors.white` or `Colors.black87` based on `Brightness.dark`.
- **Wallet Readability**:
  - Addressed wallet cards previously forced into bright `amber/green` backgrounds that burned eyes in dark mode. Re-routed the backgrounds logically in dark mode by utilizing `.withValues(alpha: 0.3)` constraints against darker shades (`Colors.amber.shade900`, `Colors.green.shade900`).
  - Conditioned forced `Colors.black87` wallet addresses to contrast white/black correctly.
- **Admin UI / Mission Panels**:
  - Replaced hard-colored `X` (Twitter) generic icon in `MissionCard` and `AdminMissionsScreen` from `Colors.black` to respect the system brightness, rectifying an issue where the logo was entirely invisible on `Color(0xFF1E1E1E)` dark cards.
  - Removed forced `Colors.white` tile colors and `grey.shade200` borders in the main `AdminScreen` panel.
  - Updated the "Suspicious User" card backgrounds in `AdminUsersScreen` to use a transparent `Colors.red.shade900.withValues(alpha: 0.3)` overlay in dark mode instead of glaring `red.shade50`.
  - Fixed hardcoded "User Matching Data" container backgrounds to use a dark grey surface instead of stark `grey.shade100`.
  - Dynamically altered state chips inside `AdminUserMissionsScreen` to properly differentiate against dark mode backgrounds using `.shade900` variations.
- **Dashboard Metrics**:
  - Re-routed 'catoshi' strings from being unreadable (`Colors.white70` on light mode card logic) to switch reliably based on context theme.

## Verification
- Code successfully modifies the IP tracking to utilize reverse proxy header forwarding.
- Frontend fetches physical IP, solving the Flag CDN UI mismatch.
- Admin portal connects natively to the unmark API with state refresh functionality.

### 9. Profile Password Change
- **Backend API**: Added a `ChangePasswordRequest` schema and `PUT /auth/users/me/password` endpoint. Validates that the provided `old_password` hashes to match the existing user's DB hash before saving a newly hashed `new_password`.
- **Frontend State**: Expanded `ApiService` and `AuthProvider` with the `changePassword(oldPassword, newPassword)` network methods.
- **Frontend UI**: Removed the "Coming Soon" placeholder on the `ProfileScreen`'s "Change Password" list tile. Tapping it now triggers an interactive material `AlertDialog` with form validation (confirm password fields, obscure text).

### 10. Social ID Overwrite Tracking & Admin Match UI
- **Backend Enforcement**: Intercepted Social ID updates in `PUT /users/me/profile`. Changing any verified ID immediately resets `verified=False` and revokes 100,000 Catoshi rewards. Furthermore, *any* update down this path creates an explicit immutable `SOCIAL_PROFILE_CHANGED` log in the `suspicious_activities` history, acting as a direct audit trail for fraud detection.
- **Admin Evidence Match UI**: Enhanced the `SuspiciousActivityResponse` nested models to pass related user metadata up. The `AdminUsersScreen` in the app has been augmented: the detailed Evidence Log popup now presents the linked user's IP, Device ID, and matching Social IDs stacked cleanly beneath the primary activity log, giving admins an unambiguous 1:1 overlap comparison.

### 11. Granular Suspicious Activity Resolution
- **Backend Tracking**: Implemented an explicit tracking parameter by bolting an `is_resolved` dynamic boolean column onto the core `suspicious_activities` database table logic.
- **Sub-Route De-escalation Mechanism**: Brought online a granular new resolution route (`POST /admin/suspicious-activity/{id}/resolve`). Rather than the historic "Unmark as Safe" single trigger that bypassed granular alerts indiscriminately, this resolver targets independent evidence vectors explicitly. Resolving an independent alarm prompts a dynamic look-forward function that sweeps the registry for *other* outstanding alarms; it will automatically reset the root `user.is_suspicious` red flag only if the ledger returns definitively null.
- **Admin Users App Integration**:
    - Relabeled the overarching Matching Display Title from `User Matching Data:` to `Current User Data (${username}):` in order to clear up any contextual confusion against the isolated individual `Linked User:` sub-block items immediately beneath it, explicitly differentiating between the User's intrinsic identity vs. detected overlaps.
    - Updated each specific iterated Evidence Log inside the display Modal to embed its own interactive "Mark as Resolved" trailing UI Checkmark. Clicking this calls the explicit API function and refreshes the modal seamlessly.
