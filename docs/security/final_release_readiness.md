# Final open-source release readiness

Sweep date: generated as part of release prep (no secret rotation, no history rewrite in this pass).  
**Scope:** whole repo — mobile OSS packaging, docs consistency, auth contract alignment, CI assumptions.

---

## Verified OK (current tree)

### 1) `google-services.json` references vs example + injection

| Location | Status |
|----------|--------|
| `cat_poe/android/app/build.gradle.kts` | Applies `com.google.gms.google-services` — expects **`android/app/google-services.json`** at build time (standard). |
| `cat_poe/lib/main.dart` | Comment only; Firebase init swallows errors if file missing. |
| `cat_poe/.gitignore` | Ignores `/android/app/google-services.json`. |
| `cat_poe/android/app/google-services.json.example` | Committed template; forks copy or CI injects real file. |
| `cat_poe/docs/firebase_fork_setup.md`, `cat_poe/docs/BUILD_RUNBOOK.md`, `cat_poe/README.md` | Describe copy / download / CI injection. |
| `.gitleaks.toml` | Allowlists **`google-services.json.example`** only (repo root). |

**Gradle does not read `.example` automatically** — developers must `cp google-services.json.example google-services.json` and replace with Firebase download, or CI must write `google-services.json` before `flutter build` (documented in `firebase_fork_setup.md` §6).

### 2) Flutter ↔ backend auth contract (code review)

| Requirement | Implementation |
|---------------|------------------|
| Signup ack-only `{ "message" }` | `cat_poe/lib/providers/auth_provider.dart` **61–69** — `SignupAck.fromJson`. |
| Refresh returns new refresh token | `cat_poe/lib/services/api_service.dart` **90–101** — `AuthTokenPayload` + `saveTokens(access, refresh)`. |
| Invalid/missing tokens on refresh | Same file **92–105** — `clearTokens()` on bad payload. |
| Reset password clears local session | `cat_poe/lib/providers/auth_provider.dart` **139–143** — `clearTokens()`, `_user` / `_profileImagePath` cleared. |
| Login / verify require both tokens | `auth_provider.dart` **39–42**, **87–90** — `AuthTokenPayload.fromJson`. |

Unit tests: `cat_poe/test/auth_api_responses_test.dart`.

### 3) CI and committed secrets

| Workflow | Finding |
|----------|---------|
| `.github/workflows/ci.yml` | **Backend only** — `pytest` in `cat_poe_backend` with **inline CI env** (`SECRET_KEY`, `DATABASE_URL`). **Does not** build Flutter; **does not** require `google-services.json`. |
| `.github/workflows/secret-scan.yml` | Full-history checkout + gitleaks-action. |
| `.github/workflows/dependency-review.yml` | Dependency review only. |

**No CI job assumes a committed `google-services.json`.**

---

## Doc cross-links (mutual consistency)

| Doc | Role |
|-----|------|
| `SECURITY.md` | Reporting, scope, secrets handling pointer to checklist. |
| `docs/setup.md` | Backend `.env.example` + Flutter entry; should mention Firebase template (patched). |
| `docs/self-hosting.md` | Own credentials + mobile build; patched to link Firebase fork doc. |
| `docs/open_source_security_checklist.md` | Master process; `google-services` bullet clarified (patched). |
| `cat_poe/docs/BUILD_RUNBOOK.md` | Dev/staging/prod commands + prerequisites table. |
| `cat_poe/docs/firebase_fork_setup.md` | Package name, SHA, API restrictions, AdMob, CI snippet. |
| `cat_poe/docs/mobile_auth_contract_update.md` | Auth API shape for mobile. |
| `docs/security/mobile_config_hardening.md` | Env defines, Firebase gitignore policy. |
| `docs/security/history_rewrite_plan.md` | If secrets were in history. |

---

## Stale or superseded docs (human triage)

| File | Issue |
|------|--------|
| `docs/security/mobile_audit.md` | Written for an older tree (line numbers, “hardcoded API”, network config). **Superseded** for gating by this file + `mobile_config_hardening.md`. Banner added in patch. |
| `CHANGELOG.md` | Historical; may still say Firebase config was “integrated” without noting gitignore — optional changelog entry when releasing. |

---

## Must do before public

1. **Confirm env files are not tracked:** `git ls-files cat_poe_backend/.env cat_poe_backend/.env.production` should print **nothing**. If either path appears, **remove from the index**, ensure `.gitignore` covers them, rely on `.env.example` + docs, and **rotate** any secrets that were ever committed.
2. **Replace `SECURITY.md` placeholders** — **lines 13–14**: `security@YOURDOMAIN` and enable private reporting in GitHub settings.
3. **Ops docs** — `discord_bot_setup.md`, beta instruction files, and `privacy-policy.md` use placeholders (`YOUR_*`, `YOURDOMAIN`). **Maintainers must replace** with real contact URLs, Play links, and privacy email before shipping a branded public app.
4. **Confirm `google-services.json` is absent from `git ls-files`** under `cat_poe/android/app/` (after maintainers commit the gitignore + removal if not already on default branch).
5. **Run** `gitleaks` / GitHub secret scanning on the default branch after the above.

---

## Should do soon after public

1. **Add a Flutter CI job** (optional) that runs `flutter test` with a **generated** `google-services.json` from secrets — keeps mobile from regressing; not required if you only CI the backend.
2. **Update `CHANGELOG.md`** with OSS packaging (gitignored Firebase file, auth contract, etc.).
3. **Refresh `docs/security/mobile_audit.md`** or archive it in favor of `mobile_config_hardening.md` + this readiness doc.
4. **Enable** GitHub **private vulnerability reporting** and **push protection** for secrets (if not already).
5. **Reconcile `cat_poe_backend/README.md`** with `docs/setup.md` (Quick Start still implies default docker passwords; self-hosters should follow `docs/self-hosting.md`).

---

## Quick command references (maintainers)

```bash
# Tracked env files (should be empty for ideal OSS)
git ls-files cat_poe_backend/.env cat_poe_backend/.env.production

# Tracked Firebase config (should not list google-services.json)
git ls-files cat_poe/android/app/google-services.json cat_poe/android/app/google-services.json.example
```

---

*End of release readiness sweep deliverable.*
