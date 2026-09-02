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
# Exit status: 0 = all certs healthy; 1 = at least one expired or within WARN_DAYS.
# Intended for cron on the production host, e.g. daily alongside cron_backup.sh:
#   0 7 * * *  cd /opt/catcoin-backend && ./check_cert_expiry.sh || \
#              mail -s "catcoin: TLS cert expiry warning" you@example.com
#
# Override defaults via env: WARN_DAYS=30 SSL_DIR=./ssl ./check_cert_expiry.sh
set -euo pipefail
cd "$(dirname "$0")"

WARN_DAYS="${WARN_DAYS:-14}"
SSL_DIR="${SSL_DIR:-./ssl}"

now=$(date +%s)
rc=0
found=0

for pem in "$SSL_DIR"/*fullchain.pem; do
    [ -e "$pem" ] || continue
    found=1
    end=$(openssl x509 -enddate -noout -in "$pem" | cut -d= -f2)
    end_epoch=$(date -d "$end" +%s)
    days=$(( (end_epoch - now) / 86400 ))
    cn=$(openssl x509 -subject -noout -in "$pem" 2>/dev/null | sed 's/.*CN *= *//')

    if [ "$days" -lt 0 ]; then
        echo "EXPIRED: $pem (CN=$cn) expired $(( -days )) day(s) ago on $end"
        rc=1
    elif [ "$days" -le "$WARN_DAYS" ]; then
        echo "WARNING: $pem (CN=$cn) expires in $days day(s) on $end"
        rc=1
    else
        echo "OK:      $pem (CN=$cn) valid for $days more day(s) (until $end)"
    fi
done

if [ "$found" -eq 0 ]; then
    echo "ERROR: no *fullchain.pem files found in $SSL_DIR" >&2
    exit 1
fi

exit $rc
