# Public snapshot — documentation & audit artifacts (final pass)

**Date:** 2026-04-13  
**Scope:** Audit/summary docs only; application source was not modified except where noted elsewhere (e.g. `.gemini/tmp` path hygiene).

## What was redacted

- **`public_release_scrub_report.md`:** All **literal** former credentials, AdMob publisher strings, Discord/Telegram/X identifiers, public IPv4, personal email, test defaults, and machine paths in the finding tables and patch examples were replaced with **descriptive placeholders** and pointers to **`CHANGE_SUMMARY.md`**. Severity and file targets remain useful for reviewers.
- **`docs/security/history_rewrite_plan.md`:** Wording now requires **`git ls-files` verification** instead of asserting specific files are tracked.
- **`docs/security/final_release_readiness.md`:** Same — “must verify untracked” instead of stating `.env` files are tracked.

## Files safe to include in a public snapshot (this category)

Typical **OK for OSS** (review for product accuracy, not for secret literals):

| Area | Examples |
|------|----------|
| Scrub / changelog artifacts (redacted) | `public_release_scrub_report.md`, `CHANGE_SUMMARY.md`, this file |
| Security guidance | `docs/security/*.md`, `docs/open_source_security_checklist.md`, `SECURITY.md` |
| Setup & hosting | `docs/setup.md`, `docs/self-hosting.md`, `cat_poe/docs/BUILD_RUNBOOK.md`, `cat_poe/docs/firebase_fork_setup.md` |
| Backend README / deploy templates | `cat_poe_backend/README.md`, `DEPLOYMENT.md`, `MIRROR_DEPLOY_README.md`, `QUICK_REFERENCE.md`, `DEPLOY_README.txt` |
| Integration setup guides | `discord_bot_setup.md`, `telegram_setup.md`, `twitter_setup.md`, `BETA_TESTING_INSTRUCTIONS_*.md`, `PHASE1_DEPLOY_README.md` *(replace `YOUR_*` before branded release)* |
| Policy templates | `privacy-policy.md` *(placeholders)* |
| CI | `.github/workflows/*.yml` *(no pasted secrets; uses `secrets.*` or test-only literals)* |

Re-run `rg` for your org’s token shapes before tagging a release.

## Exclude from the public snapshot (or never commit)

| Pattern / path | Reason |
|----------------|--------|
| `**/.env`, `**/.env.*` (except `.env.example`) | Real credentials |
| `**/google-services.json` (real), `**/GoogleService-Info.plist` (real) | Firebase client secrets / project binding |
| `**/key.properties`, `**/*.jks`, `**/*.keystore`, `**/*.p12` | Android signing |
| `cat_poe_backend/ssl/privkey.pem`, `**/*.key` (private), raw `*.pem` chains if sensitive | TLS private material |
| `**/*firebase-adminsdk*.json`, `**/serviceAccount*.json` | Server Firebase credentials |
| `**/id_rsa`, `**/id_ed25519`, `**/*.ppk` | SSH private keys |
| `cat_poe/.gemini/tmp/**` | Ephemeral tooling; was machine-specific paths *(now script-relative if kept; still recommended to **gitignore** and drop from exports)* |
| `cat_poe_backend/temp_deploy_staging/**` | Stale snapshot tree — easy to drift; scan or omit |
| Anything matching internal URL/token patterns after `gitleaks` / GitHub secret scanning | Case-by-case |

## Maintainer checklist before `git archive` / public mirror

```bash
git ls-files cat_poe_backend/.env cat_poe_backend/.env.production cat_poe/android/app/google-services.json
# expect: no output

rg -n "BEGIN (RSA |EC )?PRIVATE KEY|ghp_[A-Za-z0-9]{20,}" --glob '*.md' .
# expect: no unexpected secret-shaped literals in docs
```

---

*End of audit note.*
