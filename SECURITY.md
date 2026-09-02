# Security Policy

## Supported versions

Security fixes are applied to the default development branch (for example `main`). Older release branches may not receive backports unless maintainers explicitly support them.

## Reporting a vulnerability

**Do not** open a public GitHub issue for exploitable security bugs.

Please report vulnerabilities privately via **GitHub's private vulnerability reporting**:
[Open a security advisory on this repository](../../security/advisories/new).

(Maintainers must enable private vulnerability reporting under **Settings → Code security and analysis** before this link works.)

Include enough detail to reproduce the issue, affected components (Android app, backend API, infrastructure), and your assessment of impact if you have one. We aim to acknowledge new reports within 5 business days.

## Scope

In scope for coordinated disclosure, when maintained by this project:

- Backend API (`cat_poe_backend`)
- Flutter / Android client (`cat_poe`)
- Official deployment configuration examples in this repository

## Out of scope

- Third-party services (Google Play, ad networks, Firebase, X/Twitter, etc.) except where this repo’s integration is clearly flawed
- Forks or unofficial builds
- Physical device theft or OS-level malware on user devices

## Disclosure expectations

We ask for reasonable time to investigate and release a fix before public disclosure. Credit in advisories is offered when reporters want it.

## Secrets handling

If you discover **exposed secrets** (API keys, tokens, private keys, database passwords) in this repository or its history:

1. Report privately (do not paste the secret in public issues).
2. Assume the material is compromised: **revoke and rotate** it immediately.
3. Maintainer action: remove from current tree, rewrite Git history if needed, and re-run secret scanning before the repo is public.

See `docs/open_source_security_checklist.md` for the full open-source security process.

## Open-source release pointers

- **Local setup:** `docs/setup.md`
- **Self-hosting:** `docs/self-hosting.md`
- **Release gate / blockers:** `docs/security/final_release_readiness.md`
- **Flutter builds (dev/staging/prod):** `cat_poe/docs/BUILD_RUNBOOK.md`
- **Firebase Android (forks, `google-services.json`):** `cat_poe/docs/firebase_fork_setup.md`
- **Mobile auth API vs backend:** `cat_poe/docs/mobile_auth_contract_update.md`
