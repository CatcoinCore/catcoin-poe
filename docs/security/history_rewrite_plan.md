# History rewrite inventory — leaked secrets (plan only)

**Do not run history-rewriting commands on the canonical remote without maintainer approval, backups, and a coordinated force-push plan.** This document inventories likely sensitive paths in **this** repository (as of the inventory pass), gives **exact** `git filter-repo` command candidates, and lists post-rewrite human and verification steps.

---

## 1. Enumerated sensitive and high-risk paths

### 1.1 Paths that must never be public in the index (verify with `git ls-files`)

Run `git ls-files` on the paths below before publishing. **If any appear as tracked files**, treat their **contents** as compromised in history and in every fork or mirror; rotate secrets and consider `git filter-repo` per section 3.

| Path | Risk | Typical contents | Rewrite action |
|------|------|------------------|----------------|
| `cat_poe_backend/.env` | **Critical** | DB URL, `SECRET_KEY`, SMTP, bot tokens, API keys | Remove from all commits **or** replace blobs with a sterile template; **rotate every secret** that ever appeared. |
| `cat_poe_backend/.env.production` | **Critical** | Production-oriented env | Same as `.env`. |
| `cat_poe/android/app/google-services.json` | **High** (client / abuse) | Firebase project metadata, Android API key, package names | Remove or replace with a **non-production** example; restrict keys in Google Cloud; consider new Firebase app if key was unrestricted. |
| `cat_poe_backend/docker-compose.prod.yml` | **Medium** | References `env_file: .env`; structure may imply deployment layout | Usually **keep** file if it contains no literals; if any real hostnames/tokens were ever committed, scrub those lines or remove file from history. |
| `cat_poe_backend/docker-compose.yml` | **Low–medium** | Default dev placeholders; verify no real passwords were ever committed | Review history; scrub if literals appeared. |

### 1.2 Ignored today but commonly leaked via history or mistake

These match `.gitignore` / conventions; include in **history** audit even if absent from current `HEAD`.

| Pattern / path | Notes |
|----------------|--------|
| `**/local.properties` | SDK path; sometimes contained keys in other projects. |
| `**/key.properties`, `**/*.jks`, `**/*.keystore`, `**/*.p12` | Android signing; catastrophic if committed. |
| `cat_poe_backend/ssl/*.pem`, `*.key` | TLS private keys. |
| `.env`, `.env.*` (repo root or elsewhere) | Any copy outside `cat_poe_backend/`. |
| `**/GoogleService-Info.plist` | iOS Firebase (not currently listed as tracked here; still scan history). |
| `**/serviceAccount*.json`, `**/*firebase-adminsdk*.json` | Server credentials — must never be in app repos. |
| `**/id_rsa`, `**/id_ed25519`, `**/*.ppk` | SSH private keys. |
| `cat_poe_backend/temp_deploy_staging/**` | Staging snapshots — scan for pasted secrets. |
| `cat_poe/android/build/**` | Should not be tracked; if ever committed, may contain cached paths or configs. |

### 1.3 Files to manually review in history (content-dependent)

Not automatically “secrets,” but often copy-pasted credentials appear here:

- `cat_poe_backend/debug_x_config.py`, `post_to_community.py`, `verify_*_config.py`
- `BETA_TESTING_INSTRUCTIONS_*.md`, `*_setup.md`, `PHASE1_DEPLOY_README.md`, `DEPLOYMENT.md`
- `cat_poe_backend/test_main.http`
- `.github/workflows/*.yml` (ensure no pasted literals; `secrets.*` references are fine)

### 1.4 Discovery commands (read-only, safe to run)

Map **when** a path entered history and on which branches:

```bash
# Replace REMOTE/BRANCH as needed (e.g. origin/main).
git log --oneline --follow -- cat_poe_backend/.env
git log --oneline --follow -- cat_poe_backend/.env.production
git log --oneline --follow -- cat_poe/android/app/google-services.json
```

List all commits that touched sensitive paths:

```bash
git log --oneline --all -- cat_poe_backend/.env cat_poe_backend/.env.production cat_poe/android/app/google-services.json
```

Search **current tree** for common secret shapes (tune patterns to your org):

```bash
rg -n "SECRET_KEY|API_KEY|api_key|password\\s*=|BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|AIza[0-9A-Za-z_-]{35}" --glob '!*.png' --glob '!*.jpg' --glob '!*.ico'
```

Search **full history** without checkout (heavy):

```bash
git rev-list --all | while read c; do git grep -n "SECRET_KEY" "$c" && echo "in $c"; done
```

(Limit to path prefixes in practice, e.g. `git log -S 'SECRET_KEY' --oneline --all`.)

```bash
git log -S 'SECRET_KEY' --oneline --all -- cat_poe_backend/
git log -S 'SMTP_PASSWORD' --oneline --all --
```

---

## 2. Prerequisites: `git-filter-repo` and safety

Install (examples):

```bash
# Debian/Ubuntu
sudo apt install git-filter-repo

# pip (user install)
pip install git-filter-repo
```

**Before any rewrite:** create a **bare backup** mirror (run from parent of repo clone):

```bash
git clone --mirror /path/to/catcoin2 catcoin2-backup-$(date +%F).git
```

Or from remote:

```bash
git clone --mirror https://github.com/ORG/catcoin2.git catcoin2-backup-$(date +%F).git
```

Rewrites **must** be done on a **fresh clone** or the backup, not the only copy.

---

## 3. `git filter-repo` command candidates (exact patterns)

**Warning:** These rewrite **all** refs in the clone. Coordinates with **force-push** and fork disruption (section 4).

### 3.1 Remove specific files entirely from history

Removes the path in every commit; working tree in the rewritten repo will also not contain them until re-added from templates.

```bash
cd /path/to/fresh/clone/catcoin2

git filter-repo --force \
  --invert-paths \
  --path cat_poe_backend/.env \
  --path cat_poe_backend/.env.production \
  --path cat_poe/android/app/google-services.json
```

Optional: add more `--path` lines for any other files identified in section 1.

### 3.2 Remove files and replace with checked-in templates (two-step)

After `filter-repo` removal, on a **new branch** from rewritten `main`:

1. Copy from `.env.example` to `.env` locally only (never commit real secrets).
2. Add `google-services.json.example` (placeholder) and document in README.

Commands for the **rewrite** step only:

```bash
git filter-repo --force \
  --invert-paths \
  --path cat_poe_backend/.env \
  --path cat_poe_backend/.env.production \
  --path cat_poe/android/app/google-services.json
```

### 3.3 Redact inline secrets without deleting whole files (`--replace-text`)

Create a file `replacements.txt` (one mapping per line; use unique enough strings to avoid collateral damage):

```text
# replacements.txt — example format (replace LEFT with RIGHT in all blobs)
# literal_secret_string==>REDACTED_ROTATE_ME
# smtp_password_here==>REDACTED_ROTATE_ME
```

Then:

```bash
git filter-repo --force --replace-text replacements.txt
```

Combine with path filtering is possible using multiple invocations (do replacements first or paths first depending on goal; test on a copy).

### 3.4 Push rewritten history to GitHub (maintainers only)

After verification (section 5):

```bash
git remote add origin https://github.com/ORG/catcoin2.git
# If remote already exists:
# git remote set-url origin https://github.com/ORG/catcoin2.git

git push --force --prune origin refs/heads/*:refs/heads/*
git push --force --prune origin refs/tags/*:refs/tags/*
```

If you use Git LFS, add the documented `git lfs` push steps from GitHub docs.

---

## 4. Collaborator cleanup checklist (after force-push)

- [ ] **Announce** the rewrite window: date/time, reason (secret leak), and that **all clones must be re-synced**.
- [ ] **Rotate** every credential that appeared in any removed/scrubbed file (DB passwords, `SECRET_KEY`, JWT signing keys, SMTP, OAuth/bot tokens, Firebase/API keys if abused, signing keys if keystores leaked).
- [ ] **Invalidate** old deploy artifacts, CI variables, and Docker images built from pre-rewrite commits if they embedded env files.
- [ ] **Maintainers:** force-push **all** protected branches that matter (`main`, `master`, `production`, release branches).
- [ ] **Contributors:** for each local clone, either **delete and re-clone** or:
  ```bash
  git fetch origin
  git checkout main
  git reset --hard origin/main
  ```
  (Orphaned local branches pointing at old SHAs should be deleted or rebased.)
- [ ] **Open PRs:** GitHub may show conflicts; close and reopen from forks rebased onto new `main`, or ask authors to **re-fork** if history is incompatible.
- [ ] **Forks:** Public forks **retain old history** until owners reset them. Publish a **security advisory** or pinned issue instructing fork owners to delete the fork and re-fork, or to hard-reset to the new upstream default branch (only if they have no unique work).
- [ ] **Mirrors** (internal clones, CI caches, package mirrors): update or delete.
- [ ] **Tags/releases:** Old release tags pointing at pre-rewrite commits may still be downloadable; delete tags on remote and recreate on new commits if you need clean releases, or accept that old tags are “toxic.”

---

## 5. Post-rewrite verification checklist

### 5.1 Gitleaks (full history)

From repo root:

```bash
gitleaks detect --source . --verbose --no-git
```

With Git history (default):

```bash
gitleaks detect --source . --verbose
```

Use the repo’s `.gitleaks.toml` (allowlist targets **`google-services.json.example`** only; real **`google-services.json`** is gitignored on `HEAD`). For historic leaks, scan old commits for `cat_poe/android/app/google-services.json` without allowlist on a disposable clone.

### 5.2 Grep / ripgrep spot checks (current `HEAD` after re-add templates)

```bash
rg -n "password|secret|token|api_key|AIza|sk_live|BEGIN PRIVATE" \
  --glob '!**/build/**' --glob '!**/.dart_tool/**' --glob '!**/node_modules/**'
```

### 5.3 GitHub secret scanning and push protection

- Organization or repository: **Settings → Code security and analysis** — enable **Secret scanning** (and **Push protection** if available).
- After push, open **Security** tab → review alerts; resolve or dismiss with documented rationale.
- For custom patterns (internal token formats), add **secret scanning custom patterns** if your plan supports them.

### 5.4 Clone / fork coordination notes

- **New contributors:** clone **after** the force-push; document the new baseline SHA in the announcement.
- **Existing contributors:** `git pull` **will fail** on non-fast-forward; they must reset or re-clone (section 4).
- **Fork workflow:** Instruct: `git remote add upstream https://github.com/ORG/catcoin2.git` then `git fetch upstream` and `git reset --hard upstream/main` **only if** they have no commits to preserve; otherwise `git rebase` onto new `upstream/main` is often impossible after a full rewrite — **re-fork** is simpler.
- **Downstream packages / submodules:** Bump submodule SHAs to new commits; old SHAs are invalid for a clean audit story.

### 5.5 Optional: post-rewrite integrity

```bash
git fsck --full
git rev-list --objects --all | wc -l   # sanity vs pre-backup
```

---

## 6. Operational reminder

- **History rewrite does not rotate secrets.** Assume anything that touched the old commits is **known**; rotate and restrict first or in parallel.
- **Do not execute** the destructive commands in this document on production remotes until backups and communication plans are complete.
- Keep this inventory updated when new sensitive paths are added to tracking.
