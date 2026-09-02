# Auth hardening (cat_poe_backend)

This document describes production-oriented changes to login, refresh, logout, signup, email verification, password reset, and related rate limiting. Scope is minimal hardening, not a full auth redesign.

## Refresh token rotation

- Each refresh token row has a **`family_id`** (UUID). New login/verification sessions start a new family.
- **`POST /auth/refresh`** accepts a refresh token once: the row is marked **`revoked`**, and a **new** refresh token is returned in the same family.
- Clients **must persist the new refresh token** from every refresh response; the previous value becomes invalid immediately after a successful refresh.
- **Replay detection:** If a client presents a refresh token that is **already revoked**, the API treats this as reuse of a stale token, revokes **all** refresh tokens in that **family** for that user, and returns **401** with a generic message (same as unknown/expired token).

**Migration:** `alembic upgrade head` — revision **`auth_hardening_001`** (`auth_hardening_refresh_family_and_reset_otp.py`) adds `refresh_tokens.family_id` (backfilled) and user columns `password_reset_code`, `password_reset_expires`.

## Password reset vs email verification OTP

- **Email verification** uses `users.verification_code` + `users.verification_code_expires`.
- **Password reset** uses **`users.password_reset_code`** + **`users.password_reset_expires`** only.
- Issuing a **forgot-password** code clears verification OTP fields; issuing a **resend verification** code clears password-reset fields. Codes are **single-use** and compared with timing-safe checks; expiry is enforced.

## Rate limiting (anti-automation)

In-process sliding-window limits (per server process). Not shared across workers or hosts.

| Endpoint / flow        | Settings (defaults)                    | Window   |
|------------------------|--------------------------------------|----------|
| Signup                 | `AUTH_RL_SIGNUP_PER_HOUR_IP` (20)    | 1 hour   |
| Login                  | `AUTH_RL_LOGIN_PER_MINUTE_IP` (30)   | 1 minute |
| Forgot password        | `AUTH_RL_FORGOT_PER_HOUR_IP` (10), `AUTH_RL_FORGOT_PER_HOUR_EMAIL` (5) | 1 hour |
| Resend verification    | `AUTH_RL_RESEND_PER_HOUR_IP` (15), `AUTH_RL_RESEND_PER_HOUR_EMAIL` (5) | 1 hour |
| Verify email           | `AUTH_RL_VERIFY_PER_MINUTE_IP` (30)  | 1 minute |
| Reset password         | `AUTH_RL_RESET_PER_MINUTE_IP` (15)   | 1 minute |

**Disable for tests / debugging:** `DISABLE_AUTH_RATE_LIMIT=true` in `.env` or `DISABLE_AUTH_RATE_LIMIT=1` in the environment. The test suite sets this by default in `tests/conftest.py`.

## Enumeration-resistant responses

- **`POST /auth/signup`:** Always returns **`{ "message": "<SIGNUP_ACK>" }`** for both success and duplicate email (HTTP 200). The previous JSON user body is **removed** — clients should rely on email for onboarding details.
- **`POST /auth/forgot-password`** and **`POST /auth/resend-code`:** Generic acknowledgements whether or not the email exists or needs an action.
- **`POST /auth/verify-email`** / **`POST /auth/reset-password`:** Failed validation uses stable messages (`INVALID_VERIFICATION_CODE`, `INVALID_RESET_CODE`) without distinguishing unknown email vs wrong code where practical.

## Operational notes

- For multi-worker or multi-region deployments, replace or supplement in-process limits with a shared store (e.g. Redis) using the same key shapes.
- After deploying migration **`auth_hardening_001`**, run **`alembic upgrade head`** on each database before rolling out application code that depends on new columns.

## Breaking changes summary

1. **`POST /auth/signup`** response model is **`SignupAckResponse`** (message only), not **`UserResponse`**.
2. **`POST /auth/refresh`** returns a **new** `refresh_token` string on every successful call; clients must update stored credentials.
