# TLS certificate renewal runbook (poe.catcoin.in)

How HTTPS certs are issued, renewed, and delivered to nginx for the Catcoin PoE
backend — and how to recover when the app reports the server as unreachable.

## TL;DR recovery

If the app can't reach the backend and `https://poe.catcoin.in/health` fails the
TLS handshake (`SEC_E_CERT_EXPIRED` / `HandshakeException`), the cert has expired.
On the host, from the `cat_poe_backend` checkout:

```bash
# 1. Renew via the certbot webroot that nginx serves (see Architecture).
sudo certbot certonly --webroot -w ./certbot-www -d poe.catcoin.in

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

## Architecture

```
Let's Encrypt --(HTTP-01 challenge)--> catcoin_nginx :80
                                          location /.well-known/acme-challenge/
                                          root /var/www/certbot   <-- ./certbot-www (mount)

certbot -w ./certbot-www   writes the challenge token into ./certbot-www/.well-known/acme-challenge/
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
mkdir -p ./certbot-www/.well-known/acme-challenge
echo ok > ./certbot-www/.well-known/acme-challenge/testfile
curl -s http://poe.catcoin.in/.well-known/acme-challenge/testfile   # want: ok
rm ./certbot-www/.well-known/acme-challenge/testfile
```

Note: `--dry-run` does **not** run deploy hooks. Verify the hook separately by
running it by hand — it is idempotent (`cp` + `nginx -s reload`):

```bash
sudo /etc/letsencrypt/renewal-hooks/deploy/poe.sh && echo OK
```

## Early warning

[`cat_poe_backend/check_cert_expiry.sh`](../cat_poe_backend/check_cert_expiry.sh)
inspects every `*fullchain.pem` nginx actually serves and exits non-zero if any is
expired or within `WARN_DAYS` (default 14). Wire it into cron on the host so you
hear about it weeks early instead of from a user report:

```cron
0 7 * * *  cd /path/to/cat_poe_backend && ./check_cert_expiry.sh || \
           mail -s "catcoin: TLS cert expiry warning" you@example.com
```

## History — the Jun 2026 outage

- The `poe.catcoin.in` cert expired on Jun 21; the app went dark for ~2 days.
- Root cause #1: `renewal/poe.catcoin.in.conf` had a `webroot_path` one directory
  above the one nginx actually served, so the HTTP-01 challenge 404'd and
  auto-renewal had been failing silently for a full cycle. Fixed by pointing it at
  the served webroot and confirming with `--dry-run`.
- Root cause #2: no deploy hook copied the renewed cert into `./ssl`, so even a
  successful renewal left nginx serving the stale copy. Fixed by adding `poe.sh`.
