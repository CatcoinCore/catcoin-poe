#!/usr/bin/env bash
# Warn when any TLS cert that catcoin_nginx serves is near expiry.
#
# catcoin_nginx serves the *.pem files under ./ssl (a read-only mount). Those are
# copies refreshed by the certbot deploy hooks (see ops/letsencrypt/). This script
# inspects what nginx will actually present, so it catches BOTH failure modes that
# took poe.catcoin.in down in Jun 2026:
#   1. certbot renewal silently failing (cert in ./ssl ages out), and
#   2. a renewal succeeding but the new pem never being copied into ./ssl.
#
# It ALSO probes the live endpoint(s) in LIVE_HOSTS over TLS and checks the cert
# actually presented on the wire. That is the check that matters to users, and the
# one the file check cannot do: in Nov 2026 a different TLS manager displaced the
# certbot pipeline, the cert users received stopped being the files in ./ssl, and
# it expired with nothing watching it. Checking local files alone tells you about
# the pipeline you think you have; checking the wire tells you about the one you do.
#
# Exit status: 0 = all certs healthy; 1 = at least one expired, within WARN_DAYS,
# or a live host unreachable over TLS.
# Intended for cron on the production host, e.g. daily alongside cron_backup.sh:
#   0 7 * * *  cd /opt/catcoin-backend && ./check_cert_expiry.sh || \
#              mail -s "catcoin: TLS cert expiry warning" you@example.com
# The live probe needs no server access, so it can equally run from any other
# machine or a hosted uptime checker — and ideally should, so a dead host still alerts.
#
# Override defaults via env:
#   WARN_DAYS=30 SSL_DIR=./ssl LIVE_HOSTS="poe.catcoin.in" ./check_cert_expiry.sh
#   LIVE_HOSTS="" disables the live probe.
set -euo pipefail
cd "$(dirname "$0")"

WARN_DAYS="${WARN_DAYS:-14}"
SSL_DIR="${SSL_DIR:-./ssl}"
LIVE_HOSTS="${LIVE_HOSTS-poe.catcoin.in}"

now=$(date +%s)
rc=0
found=0

report() {  # label, notAfter string
    local label="$1" end="$2" end_epoch days
    end_epoch=$(date -d "$end" +%s)
    days=$(( (end_epoch - now) / 86400 ))
    if [ "$end_epoch" -le "$now" ]; then
        echo "EXPIRED: $label expired on $end"
        rc=1
    elif [ "$days" -le "$WARN_DAYS" ]; then
        echo "WARNING: $label expires in $days day(s) on $end"
        rc=1
    else
        echo "OK:      $label valid for $days more day(s) (until $end)"
    fi
}

for host in $LIVE_HOSTS; do
    found=1
    end=$(echo | timeout 20 openssl s_client -servername "$host" -connect "$host:443" 2>/dev/null \
          | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2) || true
    if [ -z "$end" ]; then
        echo "ERROR:   live $host:443 — no certificate retrieved (host down or TLS failing)"
        rc=1
        continue
    fi
    report "live $host:443" "$end"
done

for pem in "$SSL_DIR"/*fullchain.pem; do
    [ -e "$pem" ] || continue
    found=1
    end=$(openssl x509 -enddate -noout -in "$pem" | cut -d= -f2)
    cn=$(openssl x509 -subject -noout -in "$pem" 2>/dev/null | sed 's/.*CN *= *//')
    report "file $pem (CN=$cn)" "$end"
done

if [ "$found" -eq 0 ]; then
    echo "ERROR: nothing checked — no live hosts and no *fullchain.pem in $SSL_DIR" >&2
    exit 1
fi

exit $rc
