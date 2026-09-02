# FastAPI backend security audit

**Scope:** `cat_poe_backend` only.  
**Method:** Static review of route registration, `Depends()` chains, schemas, and selected services. Line numbers refer to the repository state when this document was produced.

---

## 1. Route inventory and classification

Legend: **Public** = no bearer token; **Auth** = `OAuth2PasswordBearer` / `get_current_user`; **Admin** = `get_current_user` + `user.is_admin`; **Docs** = HTTP Basic (`get_current_username_docs`).

### 1.1 `main.py` (app root)

| Method | Path | Classification | Auth dependency chain |
|--------|------|----------------|------------------------|
| — | `/static/*` (mount) | Public | `StaticFiles` |
| GET | `/debug/static` | Public | None (51–57) |
| GET | `/docs` | Docs | `get_current_username_docs` (73–75) |
| GET | `/redoc` | Docs | `get_current_username_docs` (77–79) |
| GET | `/openapi.json` | Docs | `get_current_username_docs` (81–84) |
| POST | `/admin/migrate-catoshi` | Admin | `auth.get_current_user` + `user.is_admin` (121–127) |
| GET | `/health` | Public | None (416–418) |
| GET | `/` | Public | None (420–422) |
| GET | `/app-ads.txt` | Public | `database.get_db` only (424–439) |
| GET | `/privacy-policy` | Public | None (441–444) |
| GET | `/delete-account` | Public | None (446–449) |
| GET | `/.well-known/assetlinks.json` | Public | None (451–456) |
| GET | `/.well-known/apple-app-site-association` | Public | None (458–463) |
| GET | `/invite`, `/invite/` | Public | None (465–469) |
| GET | `/invite/{code}` | Public | `database.get_db` (471–504) |

### 1.2 `routers/auth.py` — prefix `/auth`

| Method | Path | Classification | Auth dependency chain |
|--------|------|----------------|------------------------|
| POST | `/auth/signup` | Public | None (29–34) |
| POST | `/auth/verify-email` | Public | None (106–110) |
| POST | `/auth/resend-code` | Public | None (157–161) |
| POST | `/auth/login` | Public | None (191–196) |
| POST | `/auth/refresh` | Public | None (276–280) |
| POST | `/auth/logout` | Auth | `auth.get_current_user` (296–301) |
| POST | `/auth/delete-account-request` | Public (credential-gated) | None (306–310) |
| GET | `/auth/users/me` | Auth | `auth.get_current_user` (370–374) |
| PUT | `/auth/users/me/profile` | Auth | `auth.get_current_user` (431–435) |
| PUT | `/auth/users/me/showcase-badges` | Auth | `auth.get_current_user` (534–538) |
| PUT | `/auth/users/me/password` | Auth | `auth.get_current_user` (569–573) |
| POST | `/auth/users/me/referred-by` | Auth | `auth.get_current_user` (588–592) |
| POST | `/auth/users/me/reset-social-id` | Auth | `auth.get_current_user` (613–617) |
| POST | `/auth/forgot-password` | Public | None (668–672) |
| POST | `/auth/reset-password` | Public | None (707–711) |
| GET | `/auth/users/me/balance-details` | Auth | `auth.get_current_user` (738–742) |
| GET | `/auth/users/me/earnings-history` | Auth | `auth.get_current_user` (774–780) |
| POST | `/auth/users/me/withdraw` | Auth | `auth.get_current_user` (794–798) |

### 1.3 `routers/admin.py` — prefix `/v1`

| Method | Path | Classification | Auth dependency chain |
|--------|------|----------------|------------------------|
| GET | `/v1/config/` | Public | None — only `get_db` (17–21) |
| PUT | `/v1/admin/config` | Admin | `get_current_user` + `is_admin` (24–31) |
| GET | `/v1/payouts/` | Auth (self) | `get_current_user` (172–176) |
| GET/POST/PUT/DELETE | `/v1/admin/missions/*` | Admin | `get_current_user` + `is_admin` per handler (189+) |
| GET/PUT/POST/DELETE | `/v1/admin/users*` | Admin | same pattern (292+) |
| POST | `/v1/admin/x/post` | Admin | (734–742) |
| POST | `/v1/admin/bonus/generate` | Admin | (793–801) |
| POST | `/v1/admin/leaderboard/award-monthly-podium` | Admin | (830–838) |

### 1.4 `routers/config_utility.py` — prefix `/admin/config`

| Method | Path | Classification | Auth dependency chain |
|--------|------|----------------|------------------------|
| POST | `/admin/config/reset-extension-slots` | **Was public** | None (8–9) — patched to require admin |

### 1.5 `routers/mining.py` — no prefix

| Method | Path | Classification | Auth dependency chain |
|--------|------|----------------|------------------------|
| POST | `/mining/start` | Auth | `get_current_user` (52–55) |
| POST | `/mining/boost/{referral_id}` | Auth | `get_current_user` (65–69); referral ownership checked in `SessionManager.create_referral_boost_session` |
| GET | `/stats/me` | Auth | `get_current_user` (80–83) |
| POST | `/complete-sessions` | Auth | `get_current_user` (171–174) |
| POST | `/mining/extend` | Auth | `get_current_user` (183–187) |
| GET | `/mining/available-game-boosts` | Auth | `get_current_user` (199–202) |
| POST | `/mining/activate-game-boost` | Auth | `get_current_user` (213–217) |
| POST | `/mining/bonus/redeem` | Auth | `get_current_user` (223–227) |

### 1.6 `routers/missions.py` — prefix `/missions`

| Method | Path | Classification | Auth dependency chain |
|--------|------|----------------|------------------------|
| GET | `/missions/` | Auth | `get_current_user` (17–20) |
| POST | `/missions/complete` | Auth | `get_current_user` (77–83) |

### 1.7 `routers/wallets.py` — no prefix

| Method | Path | Classification | Auth dependency chain |
|--------|------|----------------|------------------------|
| POST | `/wallets` | Auth | `get_current_user` (13–17) |
| GET | `/wallets` | Auth | `get_current_user` (38–41) |
| DELETE | `/wallets/{wallet_id}` | Auth + object | `get_current_user` + `Wallet.user_id` (47–63) |
| PUT | `/wallets/{wallet_id}/primary` | Auth + object | (72–89) |
| POST | `/wallets/verify/{wallet_id}` | Auth + object | (112–131) |

### 1.8 `routers/callbacks.py` — prefix `/api/v1/callbacks`

| Method | Path | Classification | Auth dependency chain |
|--------|------|----------------|------------------------|
| GET | `/api/v1/callbacks/admob-ssv` | Public (HMAC-checked) | `get_db` (16–17) |

### 1.9 `routers/leaderboard.py` — prefix `/leaderboard`

| Method | Path | Classification | Auth dependency chain |
|--------|------|----------------|------------------------|
| GET | `/leaderboard/global` | Auth | `get_current_user` (28–32) |
| GET | `/leaderboard/referred` | Auth | (126–130) |
| GET | `/leaderboard/badges` | Auth | (168–171) |
| GET | `/leaderboard/regional` | Auth | (182–186) |
| GET | `/leaderboard/previous-month` | **Public** | None — only `get_db` (284–288) |
| GET | `/leaderboard/previous-month/summary` | Auth | `get_current_user` (359–364) |

### 1.10 `routers/game.py` — prefix `/game`

| Method | Path | Classification | Auth dependency chain |
|--------|------|----------------|------------------------|
| POST | `/game/start` | Auth | `get_current_user` (49–52) |
| POST | `/game/submit` | Auth | `get_current_user` (72–76) |
| GET | `/game/history` | Auth | `get_current_user` (285–288) |
| GET | `/game/status` | Auth | `get_current_user` (338–341) |
| GET | `/game/leaderboard/{game_type}` | **Public** | `get_db` only (394–399) |

---

## 2. Prioritized findings

### Critical

1. **Public exposure of secrets via `GET /v1/config/`**  
   Handler returns `AdminConfigResponse`, which includes `discord_bot_token`, `telegram_bot_token`, X/Twitter credentials, and `coin_explorer_api_key` (`schemas.py` 481–491, 496). Router: `routers/admin.py` 17–21. Any unauthenticated client can read these fields.

2. **Unauthenticated admin mutation `POST /admin/config/reset-extension-slots`**  
   `routers/config_utility.py` 8–15: no `Depends(auth…)`. Updates `admin_config` row for all users’ extension behavior.

### High

3. **Logout does not bind refresh token to the authenticated user**  
   `routers/auth.py` 296–304 calls `revoke_refresh_token` with any body token. `auth.py` 80–89 selects by token only and revokes. A user authenticated as A can revoke B’s refresh token if B’s token is known.

4. **`GET /debug/static` lists all files under the static tree**  
   `main.py` 51–57. No auth, no environment gate. Information disclosure and aids mapping of `/static`.

5. **Global `RequestValidationError` handler returns raw request body**  
   `main.py` 32–41: `content` includes `"body": str(exc.body)`. Can reflect large or sensitive payloads in 422 responses.

6. **`POST /auth/reset-password` shares OTP channel with email verification**  
   `routers/auth.py` 688–704: reuses `verification_code` / `verification_code_expires` for password reset. A user who can trigger verify-email flow and password-reset flow may increase race/complexity; codes are not labeled per purpose in storage (documented design risk).

### Medium

7. **Unbounded `limit` / `skip` on several endpoints**  
   Examples: `routers/admin.py` 292–335 (`skip`, `limit`); `routers/leaderboard.py` 28–30 (`limit`); `routers/game.py` 394–398 (`limit`). Large values increase DB load (DoS-ish).

8. **Admin `get_user_stats` validates UUID after DB lookup**  
   `routers/admin.py` 411–423: `select(User).where(User.id == user_id)` runs before `uuid.UUID(user_id)`. Invalid UUID shapes may hit the DB/driver instead of a clean 400.

9. **`POST /v1/admin/x/post` returns exception text on failure**  
   `routers/admin.py` 790–791: `HTTPException(..., detail=str(e))` can leak internal errors to admins’ clients (and logs already capture detail).

10. **Verbose logging on AdMob callback**  
    `routers/callbacks.py` 24–26, 36: logs full headers and query string at INFO. High-volume or sensitive query parameters increase log exposure.

11. **Public `GET /game/leaderboard/{game_type}` returns full `username`**  
    `routers/game.py` 435–442: unlike `leaderboard.py` entries that mask usernames (e.g. 83–84), this path returns `row.username` unmasked.

12. **`GET /leaderboard/previous-month` is public**  
    `routers/leaderboard.py` 284–288: returns masked usernames but still exposes rankings and balances for prior month without authentication (product may intend this; flag for abuse/scraping).

13. **`ExtensionRequest` in mining does not cap `hours`**  
    `routers/mining.py` 180–192: `hours: int` has no upper bound in schema.

14. **`UserCreate.email` is plain `str`**  
    `schemas.py` 11–14: not `EmailStr`; weaker input validation than `ResendCodeRequest` / `ResetPasswordRequest`.

15. **JWT access tokens carry only `sub` (username)**  
    `auth.py` 23–30, 97–104: no `jti`, no explicit `aud`/`iss` validation in `jwt.decode`. Revocation of access tokens is not modeled server-side (common limitation; note for threat model).

16. **`missions/complete` instant path grants rewards without async verification**  
    `routers/missions.py` 161–214: non-Discord/Telegram/Twitter/X missions complete immediately with ledger credit. If `Mission.icon` can be mis-set, this is a policy/configuration risk rather than automatic IDOR.

### Low

17. **No `CORSMiddleware` in repo**  
    Grep shows no CORS setup in `cat_poe_backend`. Behavior depends on reverse proxy; default FastAPI same-origin for browser calls unless proxy adds headers.

18. **`wallet.dict` on Pydantic v2**  
    `routers/wallets.py` 32: `wallet.dict` — if upgraded to Pydantic v2, should be `model_dump`; current risk is maintenance, not direct auth bypass.

19. **Startup migrations use f-strings in SQL**  
    `main.py` 229–232, 247–250, etc.: `col_name` is from fixed Python lists at startup, not request input. Low risk unless lists become data-driven from untrusted input.

---

## 3. Must-fix before public repo (operational)

- **Remove or strictly gate any endpoint that exposes third-party and infra secrets** — at minimum `GET /v1/config/` must not return bot tokens, X secrets, or explorer API keys (see Critical #1).  
- **Remove unauthenticated writes** — `config_utility.reset-extension-slots` (Critical #2).  
- **Rotate every secret** that may have been reachable via `GET /v1/config/` in any deployed environment (tokens, API keys).  
- **Fix refresh-token revocation binding** (High #3) before relying on logout for session lifecycle.  
- **Gate or remove `/debug/static`** in any shared/staging/production deployment (High #4).  
- **Tighten validation error responses** for production (High #5) so clients do not receive raw bodies.

---

## 4. Patches applied (top 10 actionable + one small extra)

Summary of code changes (see `git diff` for exact hunks):

| # | Finding | Change |
|---|---------|--------|
| 1 | Public config leaks secrets | Added `schemas.PublicAdminConfigResponse`; `GET /v1/config/` returns `model_validate(config)` with that type (`routers/admin.py`, `schemas.py`). |
| 2 | Open admin SQL write | `POST /admin/config/reset-extension-slots` now `Depends(auth.require_admin)` (`routers/config_utility.py`). |
| 3 | Logout revokes arbitrary token | `revoke_refresh_token` requires `acting_user_id`; logout passes `user.id` (`auth.py`, `routers/auth.py`). |
| 4 | Debug static | `GET /debug/static` → 404 unless `settings.ENVIRONMENT == "development"` (`main.py`). |
| 5 | 422 body leak | `RequestValidationError` response includes `body` only in development (`main.py`). |
| 6 | Unbounded limits | Cap `skip`/`limit` on admin user list; cap `limit` on leaderboard endpoints; cap game leaderboard `limit` (`routers/admin.py`, `routers/leaderboard.py`, `routers/game.py`). |
| 7 | UUID order | `get_user_stats` validates `user_id` as UUID before DB query (`routers/admin.py`). |
| 8 | AdMob logs | Callback logging demoted to `logger.debug` without full headers (`routers/callbacks.py`). |
| 9 | X post error leak | Generic 500 `detail`; exception logged with `logging.exception` (`routers/admin.py`). |
| 10 | Mining extend hours | `ExtensionRequest.hours` → `Field(ge=1, le=168)` (`routers/mining.py`). |
| + | Signup email validation | `UserCreate.email` → `EmailStr` (`schemas.py`). |
| + | Public game leaderboard privacy | `GET /game/leaderboard/{game_type}` masks usernames like other leaderboards (`routers/game.py`). |

---

## 5. Dependency quick reference

- **Bearer auth:** `auth.oauth2_scheme` + `auth.get_current_user` (`auth.py` 15, 91–110).  
- **Admin pattern:** inline `if not user.is_admin` after `get_current_user`, or `auth.require_admin` (`auth.py` 112–119) — not consistently used everywhere.  
- **DB session:** `database.get_db` (`database.py` 35–37).

---

*Maintainers: re-run this audit after large router or schema changes; add automated tests for “public config must not contain secret fields” and “logout cannot revoke other users’ tokens”.*
