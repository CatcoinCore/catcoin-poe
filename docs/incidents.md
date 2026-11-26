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

## 2026-11-20 — certificate expired; nginx kept serving a stale copy

**Impact.** The app was unreachable for roughly four hours. The served
certificate expired at 13:39 UTC and was replaced at about 17:30 UTC.

**What users saw.** TLS handshake failure (`certificate has expired`). Port 80
still answered with a redirect, so the server looked "up".

**Root cause — the renewed certificate never reached the directory nginx serves.**
When an emergency renewal was attempted, certbot reported *"Certificate not yet
due for renewal"*: it already held a valid, newer certificate in
`/etc/letsencrypt/live/poe.catcoin.in/`. nginx, however, serves a **copy** in
`./ssl/`, and that copy was the old certificate. Automatic renewal had worked;
delivering the result to nginx had not. This is the same failure shape as root
cause #2 of the June 2026 outage (see [cert-renewal.md](cert-renewal.md)).

The certificate's issuer had changed to a new Let's Encrypt intermediate, which
initially suggested a different TLS manager had taken over. It had not; the
issuer change is just Let's Encrypt's own rotation. The useful lesson is to
compare the live certificate against `/etc/letsencrypt/live/` **first**: if
certbot's copy is newer than what is served, the problem is delivery, not
renewal.

**Fix.**

1. Forced a fresh certificate (valid to 2027-02-18) and ran the `poe.sh` deploy
   hook by hand to copy it into `./ssl` and reload nginx. During the renewal
   itself the hooks reported errors because nginx had been stopped for a
   standalone renewal; the manual run afterwards succeeded.
2. The standalone renewal had switched `poe.catcoin.in.conf` to
   `authenticator = standalone`, which would fail at the next automatic renewal
   because nginx holds port 80. The same day it was switched to
   `authenticator = webroot` with
   `webroot_path = /opt/catcoin-backend/certbot-www`, the directory nginx serves
   for `/.well-known/acme-challenge/`, and `certbot renew --dry-run` passed. The
   previous config is kept as `poe.catcoin.in.conf.bak-20261120`.

**What changed so it does not recur.**

- `check_cert_expiry.sh` used to inspect only the files in `./ssl/`, so it could
  not see the certificate actually served. It now also connects to the live
  endpoint and checks the certificate presented there, and exits non-zero if the
  host is unreachable over TLS.

**Follow-ups.**

- [ ] Deploy the updated `check_cert_expiry.sh` to the server, `chmod +x` it,
      and schedule it — preferably off-host.
- [ ] Find out why the automatic renewal in October did not deliver the new
      certificate into `./ssl` (check `/var/log/letsencrypt/` around that date
      for deploy-hook errors).

---

## 2026-06-21 — certificate expired; renewal failing silently

See *History* in [cert-renewal.md](cert-renewal.md): the renewal webroot pointed
one directory above the one nginx served, and no deploy hook copied renewed
certificates into `./ssl`.
