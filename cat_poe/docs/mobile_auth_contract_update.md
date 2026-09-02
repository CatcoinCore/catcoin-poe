# Mobile auth contract update

Aligns the Catcoin PoE Flutter client with the hardened backend auth API.

## Signup (`POST /auth/signup`)

- **Response:** `{ "message": "<ack>" }` only. There is **no** user object, `id`, `username`, or `email` in the body.
- **Client:** Parses with `SignupAck.fromJson` and navigates to email verification as before. Duplicate and new registrations receive the **same** response shape (no client-side “email already registered” string matching).

## Refresh (`POST /auth/refresh`)

- **Response:** New **`access_token`** and new **`refresh_token`** on every successful call (one-time refresh rotation).
- **Client:** `ApiService.refreshAccessToken` persists **both** tokens. If either field is missing or empty, stored tokens are **cleared** and refresh returns `false` to avoid a half-updated session.

## Password reset (`POST /auth/reset-password`)

- **Backend:** Revokes all refresh tokens for the user.
- **Client:** After a successful reset, **`AuthProvider.resetPassword`** clears secure-storage tokens and in-memory user state so the user must sign in again.

## Login / verify-email

- **Client:** Uses `AuthTokenPayload.fromJson` so malformed bodies fail fast instead of writing null/invalid tokens.

## Files touched

- `lib/models/auth_api_responses.dart` — `SignupAck`, `AuthTokenPayload`
- `lib/providers/auth_provider.dart` — signup, login, verify, reset
- `lib/services/api_service.dart` — refresh validation + persistence
- `test/auth_api_responses_test.dart` — contract unit tests

## Upgrade note for forks

Rebuild and ship with a backend that implements the above; older APIs that return a full user from signup or the same refresh token on refresh will break the new parsers or session behavior.
