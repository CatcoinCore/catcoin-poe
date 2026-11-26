# Production incidents

Post-incident notes for the Catcoin PoE backend (`poe.catcoin.in`). Each entry
records what users saw, the root cause, how it was found, the fix, and what was
changed so it does not recur. Newest first.

The first question to ask in any "the app can't reach the server" report is
**which layer is failing**, because they look identical in the app:

| Symptom from outside | Layer | Start here |
|---|---|---|
| TCP connects, TLS handshake fails (`certificate has expired`, `HandshakeException`) | certificate | [cert-renewal.md](cert-renewal.md) |
| Ports 80/443 **refuse** connections, but port 22 answers | nothing listening on the address | check *which machine* owns the IP (incident 2026-11-26) |
| Ports time out entirely | host or network down | provider console |
| TLS fine, `/health` returns 5xx | application | container logs |

```bash
# One command that distinguishes the first three:
./check_cert_expiry.sh        # cat_poe_backend/check_cert_expiry.sh; probes the live endpoint
```

---

## 2026-11-26 — every site on the host unreachable after a server migration

**Impact.** The app could not connect at all on 2026-11-26. Every site served by
the same host was down at the same time. No data was lost and no container had
crashed.

**What users saw.** "Could not reach the server". From outside, ports 80 and 443
on the service IP *refused* connections while port 22 still answered — a
different signature from a certificate failure.

**Root cause — a duplicate IP address.** Around 2026-11-23 the whole stack was
migrated to a new server. The new server was given the service IP (the address
`poe.catcoin.in` resolves to) in addition to its own address, and the containers
there were started and stayed healthy. But the **old server still had the same
service IP configured**. Its containers had been stopped cleanly at migration
(`Exited (0)`), but its network interface kept claiming the address.

With two machines claiming one IP, the local network delivers traffic to
whichever one answered address resolution most recently. For about three days
that was the new server, so the app kept working. On 2026-11-26 the network
switched to the old server, where nothing was listening on 80/443, and every
site went down at once. Duplicate-IP faults behave exactly like this: they can
work for days and then fail without anyone changing anything.

**How it was found.**

1. Ports 80/443 *refused* rather than failing TLS → not a certificate problem.
2. SSH to the service IP warned **REMOTE HOST IDENTIFICATION HAS CHANGED**. The
   host key fingerprint is a reliable way to tell *which physical machine* is
   answering an address: it had changed to a machine whose `docker ps -a` showed
   every container stopped three days earlier.
3. The previously-trusted fingerprint was now being served by the *other*
   address, on a machine where the full stack was up and healthy (`/health` 200
   inside the backend container) and nginx was bound to the service IP.
4. `ip -4 addr` showed the service IP configured on **both** machines.

```bash
# Which machine is answering this address right now?
ssh-keyscan -t ed25519 <service-ip> | ssh-keygen -lf -
# Does this machine claim the address?
ip -4 -o addr show | grep <service-ip>
```

**Fix.** Removed the service IP from the old server's interface. Within moments
the network delivered the address to the new server, and every site returned
(`/health` 200, certificate valid) with no restarts on the new server and no
data touched.

**Do not** start the containers on the old server: they hold a stale copy of the
database from migration day, would contend for the same address, and any user
who reached them would write to a database that is then discarded.

**Follow-ups.**

- [ ] Make the removal persistent on the old server (remove the address from
      `/etc/netplan/*.yaml` and `netplan apply`), or decommission that server. A
      runtime-only `ip addr del` returns on the next reboot and reproduces this
      outage.
- [ ] Add a migration checklist step: *the service IP must be removed from the
      source machine before, or atomically with, assigning it to the target.*
- [ ] Run `check_cert_expiry.sh` (or any uptime monitor on
      `https://poe.catcoin.in/health`) **from a machine other than the server**,
      every few minutes. It fails with
      `ERROR: live poe.catcoin.in:443 — no certificate retrieved` when the site
      is unreachable, so it alerts on this class of outage as well as on
      certificate expiry.

---

## 2026-11-20 — certificate expired; renewal had been failing silently for a month

**Impact.** The app was unreachable for roughly four hours. The served
certificate expired at 13:39 UTC and was replaced at about 17:30 UTC.

**What users saw.** TLS handshake failure (`certificate has expired`). Port 80
still answered with a redirect, so the server looked "up".

**Root cause — nginx and certbot disagreed about the challenge directory.** After
the June outage, poe's renewal config was pointed at a webroot directory that
belonged to another site on the host, and the Aug 22 renewal succeeded through
it. On Sep 10 the `./certbot-www` directory was introduced, and the host's
`nginx.conf` was changed (last edited Oct 18) to serve poe's
`/.well-known/acme-challenge/` from it instead. Nobody updated `webroot_path` in
`/etc/letsencrypt/renewal/poe.catcoin.in.conf` to match.

From Oct 21, when renewal came due, certbot wrote its challenge tokens to the
old directory while nginx served the new one. Every attempt — twice a day for a
month — got a 404 from Let's Encrypt and failed silently, and the certificate
issued on Aug 22 expired on schedule.

The certificate archive is the proof: `cert5` (issued Aug 22, expires Nov 20) is
followed directly by `cert6` (issued Nov 20 during recovery). There was no
October certificate. The renewal log for October was on the pre-migration server
and is not available; the conclusion rests on the archive and on the dates of
the nginx and directory changes.

**Two red herrings worth recording.**

- The certificate's issuer had changed to a new Let's Encrypt intermediate,
  which suggested a different TLS manager had taken over. It had not; that is
  Let's Encrypt's own rotation.
- During recovery certbot said *"Certificate not yet due for renewal"*, which
  looked as if renewal had worked and only delivery had failed. It was referring
  to a certificate created minutes earlier in the same recovery session. Always
  check the dates in `/etc/letsencrypt/archive/<name>/` before concluding which
  of renewal or delivery failed.

**Fix.**

1. Forced a fresh certificate (valid to 2027-02-18) and ran the `poe.sh` deploy
   hook by hand to copy it into `./ssl` and reload nginx.
2. The emergency renewal used `--standalone`, which had switched the renewal
   config to `authenticator = standalone`. The same day it was set to
   `authenticator = webroot` with
   `webroot_path = /opt/catcoin-backend/certbot-www`, the directory nginx
   actually serves, which also corrects the original mismatch.
   `certbot renew --dry-run` passed.

**What changed so it does not recur.**

- `check_cert_expiry.sh` now probes the live endpoint, not only files on disk,
  and exits non-zero if the host is unreachable over TLS. Run off-host on a
  schedule, it would have warned 14 days before expiry.
- Rule recorded in [cert-renewal.md](cert-renewal.md): **any change to where
  nginx serves `/.well-known/acme-challenge/` must be paired with the matching
  `webroot_path` change and a `certbot renew --dry-run`.**

**Follow-ups.**

- [ ] Deploy the updated `check_cert_expiry.sh` to the server, `chmod +x` it,
      and schedule it — preferably off-host.
- [ ] Run `certbot renew --dry-run` for **every** certificate on the host. The
      other sites have their own `webroot_path` settings, and the same kind of
      mismatch would take them down the same silent way.

---

## 2026-06-21 — certificate expired; renewal failing silently

See *History* in [cert-renewal.md](cert-renewal.md): the renewal webroot pointed
one directory above the one nginx served, and no deploy hook copied renewed
certificates into `./ssl`.
