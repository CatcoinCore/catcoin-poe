# Let's Encrypt deploy hook (reference copy)

`poe.sh` is a **reference copy** of the certbot deploy hook that lives on the
production host at `/etc/letsencrypt/renewal-hooks/deploy/poe.sh`. It is kept in
version control so a host rebuild is reproducible — host state itself is not in
this repo, which is exactly why an expired cert once went unnoticed.

| Hook | Cert | Copies into `./ssl` as |
|------|------|------------------------|
| `poe.sh` | `poe.catcoin.in` | `fullchain.pem` / `privkey.pem` |

## Why it exists

`catcoin_nginx` serves **copies** of the cert from the `./ssl` mount
(`docker-compose.prod.yml`: `- ./ssl:/etc/nginx/ssl:ro`), not the live
`/etc/letsencrypt/live/...` path. So a renewal is only effective after the new
pem is copied into `./ssl` **and** nginx reloads. The deploy hook does both.
certbot runs every hook in this directory on every successful renewal; the `cp`
is idempotent and the reload is cheap.

## Installing on the host

```bash
sudo install -m 0755 poe.sh /etc/letsencrypt/renewal-hooks/deploy/
sudo certbot renew --cert-name poe.catcoin.in --dry-run   # verify renewal auth
sudo /etc/letsencrypt/renewal-hooks/deploy/poe.sh         # verify cp + reload
```

See [`docs/cert-renewal.md`](../../../docs/cert-renewal.md) for the full runbook,
including the certbot webroot the renewal challenge depends on.
