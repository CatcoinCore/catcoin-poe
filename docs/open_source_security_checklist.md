# Open Source Security Checklist

This checklist is designed for a mobile app + backend project that is about to be published publicly on GitHub.

**Current-tree gate:** see **`docs/security/final_release_readiness.md`** (blockers, CI, Firebase template, auth contract pointers).

## Goals

- Make the repository safe to open-source.
- Reduce the chance of production compromise.
- Prevent accidental secret leaks in future commits.
- Make it easy for external developers to run their own local instance without touching production.
- Preserve the brand even if the code is open.

---

## 1) Pre-publication source sanitization

### 1.1 Inventory what must never be public

Before changing repo visibility, identify and remove or relocate:

- API keys
- OAuth client secrets
- JWT signing secrets
- database passwords
- third-party service credentials
- Android signing artifacts and keystores
- service account JSON files
- internal hostnames, private IPs, VPN endpoints
- production-only config values
- customer data, sample exports, logs, crash dumps
- proprietary certificates or private keys

### 1.2 Scan the full Git history

Do not rely on the current branch contents alone.

Run at least one history-aware secret scan before publishing.

Recommended tools:

- `gitleaks`
- `trufflehog`

Suggested local commands:

```bash
# gitleaks: scan repository and history
# install first from the official project if needed
gitleaks git --verbose --redact .

# trufflehog: scan the git repo
# install first from the official project if needed
trufflehog git file://$(pwd) --results=verified,unknown
```

### 1.3 Rotate before you rewrite

If any secret was ever committed:

1. Treat it as compromised.
2. Revoke or rotate it.
3. Update production and CI/CD to use the new secret.
4. Only then rewrite Git history if needed.

Do **not** assume that deleting a file in the latest commit made the secret safe.

### 1.4 Rewrite history when necessary

If sensitive material exists in history, remove it with a history-rewrite tool such as:

- `git filter-repo`
- BFG Repo-Cleaner

After rewrite:

- force-push the cleaned history
- invalidate old clones if possible
- re-run secret scans
- verify the repo is clean before making it public

### 1.5 Add ignore and sample config files

Use:

- `.gitignore` for local-only files
- `.env.example` for documented placeholders
- `docs/setup.md` for local setup instructions

Never commit:

- `.env`
- `keystore.jks`
- `*.p12`
- `*.pem`
- real `google-services.json` (keep **gitignored**; ship **`google-services.json.example`** + fork docs — see `cat_poe/docs/firebase_fork_setup.md`)
- production credential files

---

## 2) Secrets management model

### 2.1 Local development

Local development may use:

- `.env`
- local Docker secrets
- direnv

But local secrets must remain developer-specific and untracked.

### 2.2 Production

Production should use a real secrets manager, for example:

- AWS Secrets Manager
- HashiCorp Vault
- cloud-native secret storage for your platform

Minimum expectations:

- access control by role
- auditability
- rotation capability
- environment separation
- no plaintext secrets in repository or CI variables where avoidable

### 2.3 Environment separation

Keep these completely separate:

- local/dev
- staging/test
- production

Use different:

- databases
- JWT signing keys
- OAuth credentials
- API endpoints
- storage buckets
- Android package IDs or flavors where appropriate

---

## 3) GitHub hardening before and after publication

### 3.1 Enable secret protections

Enable:

- secret scanning
- push protection
- Dependabot alerts
- dependency review
- code scanning if available

### 3.2 Add baseline workflows

Create CI checks for:

- secret scanning
- linting
- tests
- dependency review on pull requests

### 3.3 Publish an SBOM

Generate an SBOM during CI or from the repository dependency graph.
This is especially useful once outside contributors start adding dependencies.

### 3.4 Protect important branches

Protect `main` / `master` with:

- pull request reviews
- status checks
- signed commits if your team wants them
- restricted force-push

---

## 4) Android app hardening

### 4.1 Accept the threat model

Assume that:

- the APK or AAB will be inspected
- traffic patterns will be studied
- public API routes will be replayed
- attackers can run rooted devices, emulators, and instrumentation tools

Your goal is not to hide everything.
Your goal is to prevent trust in the client.

### 4.2 Obfuscate production builds

Use R8/ProGuard aggressively for release builds.

What it helps with:

- increases reverse-engineering effort
- reduces readability of production binaries
- can make casual hooking harder

What it does **not** do:

- protect secrets embedded in the app
- make client-side authorization trustworthy
- stop determined reverse engineers

### 4.3 Use Play Integrity with backend verification

Integrate Google Play Integrity and verify verdicts on the backend.
Use it as a signal for abuse detection, not as the only gate.

Recommended uses:

- protect sensitive reward-claim endpoints
- rate-limit or challenge risky sessions
- detect tampered or unofficial builds
- distinguish low-trust from higher-trust requests

Avoid treating it as perfect proof.

### 4.4 App signing hygiene

Use Play App Signing for Play-distributed builds.
Keep upload key handling separate from server credentials.
Do not commit keystores or passwords.

### 4.5 Network transport

Always require HTTPS.
Use modern TLS defaults.
Avoid cleartext traffic.

### 4.6 Certificate pinning: optional, not universal

Do **not** present certificate pinning as mandatory in every app.
Use it only when your threat model justifies the operational cost.

If you do implement it:

- prefer Android Network Security Configuration where practical
- pin backup keys as well as current keys
- document rotation and recovery steps
- test failure behavior before release

Remember:

- pinning can be bypassed in many real-world mobile attack scenarios
- poor pin management can break your own app during certificate changes

### 4.7 Root / emulator / tamper signals

Optional secondary controls:

- root detection
- emulator heuristics
- debugger / instrumentation detection
- anti-replay nonce handling

Treat all of them as risk signals, not absolute trust boundaries.

---

## 5) Backend hardening

### 5.1 Assume all clients are hostile

Your backend must not trust:

- mobile app package identity alone
- API keys embedded in the app
- hidden endpoints
- minified or obfuscated client logic

### 5.2 Strict request validation

For every endpoint:

- validate type
- validate length
- validate range
- validate enum membership
- reject unknown fields where appropriate
- constrain strings and payload sizes
- normalize and canonicalize where needed

Examples:

- if an integer is expected, reject strings
- if a UUID is expected, reject malformed IDs
- if pagination max is 100, reject 1000

### 5.3 Strong authorization

Do not stop at “user is authenticated”.

Check:

- object-level authorization
- function-level authorization
- property-level exposure
- tenant ownership where applicable
- admin-only route enforcement

Examples:

- a valid user must not be able to access another user’s wallet or profile by changing an ID
- authenticated users must not be able to call admin endpoints
- responses must not leak sensitive fields just because a serializer included them

### 5.4 Token and auth model

For native apps:

- treat the app as a public client
- do not rely on an embedded client secret
- use short-lived access tokens where possible
- rotate refresh tokens if your auth stack supports it
- bind authorization to server-side rules, not app secrecy

### 5.5 Rate limiting and abuse controls

Apply rate limiting to:

- login
- OTP
- password reset
- reward/mining claims
- wallet or transfer-like actions
- search endpoints
- expensive compute endpoints

Layer limits by:

- IP
- account
- device/session
- action type

### 5.6 Logging and monitoring

Log at least:

- auth failures
- authorization failures
- validation failures
- suspicious burst traffic
- integrity-check failures
- admin actions
- secret access events in your infrastructure

Do not log:

- access tokens
- passwords
- full secrets
- private keys

### 5.7 Replay protection

For sensitive mobile-to-backend actions, consider:

- nonce or challenge binding
- short request lifetimes
- idempotency keys where applicable
- one-time claim tokens for rewards

### 5.8 CORS and API surface

If the backend also serves web clients:

- use explicit CORS allowlists
- do not use wildcard origins with credentials
- hide internal admin tooling from public internet where possible

---

## 6) Brand and reputation guardrails

### 6.1 License the code, not the brand

Pick a standard open-source license for the codebase, for example:

- MIT
- Apache-2.0

Then separately reserve:

- project name
- logo
- mascots
- visual identity
- official backend domains

### 6.2 Add a branding policy

Create a short file such as `BRANDING.md` stating:

- code may be reused under the code license
- official name/logo may not be reused in redistributed builds without permission
- forks must remove or replace protected branding
- only your official backend and official Play listing represent the real product

### 6.3 Open-source developer posture

Document clearly that:

- community builds must use their own backend
- community developers must generate their own credentials
- public repo examples use placeholders only
- official production endpoints are not for arbitrary third-party forks unless explicitly allowed

---

## 7) Supply-chain protection

### 7.1 Dependency review

Review every new dependency for:

- maintenance activity
- license compatibility
- vulnerability history
- scope of permissions
- necessity

### 7.2 Automated dependency signals

Enable:

- Dependabot alerts
- dependency review in pull requests
- SBOM generation

### 7.3 Release provenance

For mature projects, add:

- signed release tags
- release notes
- checksums for binaries if you distribute outside Play

---

## 8) Files to add to the repo

Recommended additions:

- `SECURITY.md`
- `OPEN_SOURCE_SECURITY_CHECKLIST.md`
- `.env.example`
- `BRANDING.md`
- `docs/setup.md`
- `docs/self-hosting.md`
- `.github/dependabot.yml`
- `.github/workflows/secret-scan.yml`
- `.github/workflows/dependency-review.yml`
- `.github/workflows/ci.yml`

---

## 9) Suggested SECURITY.md outline

```md
# Security Policy

## Supported Versions
State which branches or versions receive security fixes.

## Reporting a Vulnerability
Provide a private reporting path.
Do not ask people to open public issues for exploitable bugs.

## Scope
Clarify what is in scope:
- Android app
- backend API
- official hosted services

## Out of Scope
Clarify what is not in scope if needed.

## Disclosure Expectations
State whether coordinated disclosure is expected.

## Secrets Handling
Confirm that leaked secrets should be reported privately.
```

---

## 10) Suggested .env.example outline

```env
# App
APP_ENV=development
APP_DEBUG=true
API_BASE_URL=http://localhost:8000

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/appdb

# Auth
JWT_ISSUER=your-app-dev
JWT_AUDIENCE=your-app-dev-users
JWT_SECRET=replace-me

# Optional third-party services
SENTRY_DSN=
REDIS_URL=redis://localhost:6379/0

# Android / mobile integration
PLAY_INTEGRITY_PROJECT_NUMBER=
```

---

## 11) Human review checklist before pressing “Public”

- [ ] Secret scan completed on full history
- [ ] All discovered secrets rotated or revoked
- [ ] History rewritten if needed
- [ ] `.env.example` created with placeholders only
- [ ] Production secrets moved to a secrets manager
- [ ] GitHub secret scanning and push protection enabled
- [ ] Dependabot and dependency review enabled
- [ ] `SECURITY.md` added
- [ ] `BRANDING.md` added
- [ ] License chosen and added
- [ ] Android release build checked for obfuscation and debug leakage
- [ ] Backend authorization reviewed for object/function/property-level access
- [ ] Rate limiting enabled on sensitive endpoints
- [ ] Public setup docs reviewed so contributors do not depend on your production systems
- [ ] Final manual grep for secrets completed
- [ ] Someone other than the primary author reviewed the repo

---

## 12) Recommended order of execution

1. Run secret scans.
2. Rotate leaked secrets.
3. Externalize config.
4. Add docs and sample env files.
5. Enable GitHub protections.
6. Review Android release hardening.
7. Review backend auth and validation.
8. Add CI security checks.
9. Review branding/trademark posture.
10. Make the repository public.

---

## 13) Important mindset

Open-sourcing your client code does **not** create the main security risk by itself.
The real risk is leaving secrets, over-trusting the client, weak authorization, weak abuse controls, and unclear operational boundaries.

Design the system so that:

- the client can be inspected
- requests can be replayed
- attackers know every endpoint
- secrets never live in source control
- production trust is anchored in the backend
