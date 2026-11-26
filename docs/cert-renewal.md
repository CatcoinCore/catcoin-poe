# TLS certificate renewal runbook (poe.catcoin.in)

How HTTPS certs are issued, renewed, and delivered to nginx for the Catcoin PoE
backend — and how to recover when the app reports the server as unreachable.

## TL;DR recovery

If the app can't reach the backend and `https://poe.catcoin.in/health` fails the
TLS handshake (`SEC_E_CERT_EXPIRED` / `HandshakeException`), the cert has expired.
On the host, in `/opt/catcoin-backend` (see *Production host layout* below):

```bash
# 0. Is it actually the certificate? If certbot's copy is newer than what is
#    served, renewal worked and only delivery to nginx failed: skip to step 2.
sudo openssl x509 -noout -enddate -in /etc/letsencrypt/live/poe.catcoin.in/fullchain.pem

# 1. Renew via the certbot webroot that nginx serves (see Architecture).
sudo certbot certonly --webroot -w /opt/catcoin-backend/certbot-www -d poe.catcoin.in

# 2. Copy the new cert into the dir nginx serves, then reload.
sudo /etc/letsencrypt/renewal-hooks/deploy/poe.sh

# 3. Verify (want notAfter ~90 days out, and HTTP 200).
echo | openssl s_client -servername poe.catcoin.in -connect poe.catcoin.in:443 2>/dev/null \
  | openssl x509 -noout -dates
curl -s -o /dev/null -w '%{http_code}\n' https://poe.catcoin.in/health
```

The Flutter app uses Dart's `http` client, which **hard-rejects an expired cert at
the TLS handshake** before sending any request — so an expired cert looks exactly
like "server down" even though FastAPI + nginx are up (port 80 still 301s). No app
update or restart is needed once the cert is fixed; it reconnects immediately.

**Do not use `certbot --standalone`** except as a last resort with nginx stopped:
it rewrites the renewal config to `authenticator = standalone`, and the next
automatic renewal then fails because nginx holds port 80. If you do use it,
switch the config back to `webroot` afterwards and re-run `--dry-run`.

If ports 80/443 *refuse* connections instead of failing TLS, this is not a
certificate problem; see [incidents.md](incidents.md).

## Production host layout

- The backend is deployed as a package to **`/opt/catcoin-backend`**, which is
  the contents of this repository's `cat_poe_backend/` directory placed at the
  top level. It is **not a git checkout**; `git pull` does not apply there.
- The host's `nginx.conf` is maintained on the server and differs from the copy
  in this repository. `catcoin_nginx` is the front door for **every site on the
  host**, not only Catcoin, so a change to it, or it being down, affects all of
  them.
- Renewal config: `/etc/letsencrypt/renewal/poe.catcoin.in.conf` with
  `authenticator = webroot` and
  `webroot_path = /opt/catcoin-backend/certbot-www`.
- Each site on the host has its own deploy hook in
  `/etc/letsencrypt/renewal-hooks/deploy/`. certbot runs all of them after any
  renewal, so one renewal reloads nginx several times; that is harmless.

## Architecture

```
Let's Encrypt --(HTTP-01 challenge)--> catcoin_nginx :80
                                          location /.well-known/acme-challenge/
                                          root /var/www/certbot   <-- ./certbot-www (mount)

certbot -w /opt/catcoin-backend/certbot-www   writes the challenge token into .../certbot-www/.well-known/acme-challenge/
certbot saves the cert to: /etc/letsencrypt/live/poe.catcoin.in/
deploy hook copies it to:  ./ssl/            (the ./ssl mount)
catcoin_nginx serves:      /etc/nginx/ssl/ == ./ssl   (read-only mount, COPIES)
```

Two non-obvious facts that have each caused an outage:

1. **nginx serves copies, not the live cert.** `docker-compose.prod.yml` mounts
   `- ./ssl:/etc/nginx/ssl:ro`. A successful `certbot renew` does **not** reach
   nginx until the new pem is copied into `./ssl` and nginx reloads. That is the
   job of the deploy hook under `/etc/letsencrypt/renewal-hooks/deploy/`
   (reference copy in [`cat_poe_backend/ops/letsencrypt/`](../cat_poe_backend/ops/letsencrypt/)).

2. **The HTTP-01 webroot must be the exact directory nginx serves.** nginx holds
   port 80, so `certbot --standalone` cannot bind it. Instead `nginx.conf` serves
   `/.well-known/acme-challenge/` from `/var/www/certbot`, which
   `docker-compose.prod.yml` mounts from `./certbot-www`. certbot's `-w` must point
   at that same host directory, and `webroot_path` in
   `/etc/letsencrypt/renewal/poe.catcoin.in.conf` must match it. Pointing one
   directory too high or too low makes every challenge 404 and renewal fail silently.
   **Whenever the nginx challenge location changes, update `webroot_path` for
   every affected certificate and run `certbot renew --dry-run` in the same
   change.** Skipping that step caused the Nov 2026 outage a month later.

## Cert ↔ filename map

| Domain | `./ssl` filenames (nginx.conf) | Deploy hook |
|--------|--------------------------------|-------------|
| `poe.catcoin.in` | `fullchain.pem` / `privkey.pem` | `poe.sh` |

## Verifying renewal will succeed (no rate-limit risk)

`--dry-run` uses the staging CA and forces a **real** challenge each time, so it
catches problems that a production `certonly` hides via cached authorizations:

```bash
sudo certbot renew --cert-name poe.catcoin.in --dry-run
#  want: ".../poe.catcoin.in/fullchain.pem (success)"
```

To prove the challenge path itself serves correctly:

```bash
W=/opt/catcoin-backend/certbot-www
mkdir -p $W/.well-known/acme-challenge
echo ok > $W/.well-known/acme-challenge/testfile
curl -s http://poe.catcoin.in/.well-known/acme-challenge/testfile   # want: ok
rm $W/.well-known/acme-challenge/testfile
```

Note: `--dry-run` does **not** run deploy hooks. Verify the hook separately by
running it by hand — it is idempotent (`cp` + `nginx -s reload`):

```bash
sudo /etc/letsencrypt/renewal-hooks/deploy/poe.sh && echo OK
```

## Early warning

[`cat_poe_backend/check_cert_expiry.sh`](../cat_poe_backend/check_cert_expiry.sh)
connects to the live endpoint and checks the certificate **actually presented**,
and also inspects any `*fullchain.pem` in `./ssl`. It exits non-zero if a
certificate is expired or within `WARN_DAYS` (default 14), **or if the host
cannot be reached over TLS at all**, so it catches outages, not only expiry.

Checking files alone is not enough: what nginx serves can differ from what is on
disk where you are looking, and only the live probe sees what users actually get.

The live probe needs no server access, so run it **from a machine other than the
server** (a dead server cannot report itself), every few minutes:

```cron
*/10 * * * *  /path/to/check_cert_expiry.sh || \
              mail -s "catcoin: poe.catcoin.in TLS problem" you@example.com
```

## History

Full write-ups for every outage are in [incidents.md](incidents.md).

### Nov 2026

- The certificate expired on Nov 20. Renewal had been failing silently since
  Oct 21: nginx had been changed to serve poe's challenge files from
  `./certbot-www`, but the renewal config still pointed at the previous webroot,
  so every challenge 404'd. Fixed by setting
  `webroot_path = /opt/catcoin-backend/certbot-www` and verifying with
  `--dry-run`.
- `check_cert_expiry.sh` now probes the live endpoint, since the file-only check
  could not see what users were actually served.

### Jun 2026

- The `poe.catcoin.in` cert expired on Jun 21; the app went dark for ~2 days.
- Root cause #1: `renewal/poe.catcoin.in.conf` had a `webroot_path` one directory
  above the one nginx actually served, so the HTTP-01 challenge 404'd and
  auto-renewal had been failing silently for a full cycle. Fixed by pointing it at
  the served webroot and confirming with `--dry-run`.
- Root cause #2: no deploy hook copied the renewed cert into `./ssl`, so even a
  successful renewal left nginx serving the stale copy. Fixed by adding `poe.sh`.
