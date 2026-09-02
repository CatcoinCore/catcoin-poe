#!/usr/bin/env bash
# Certbot deploy hook for poe.catcoin.in.
#
# Install on the production host at:
#   /etc/letsencrypt/renewal-hooks/deploy/poe.sh   (chmod +x)
#
# catcoin_nginx serves COPIES of the cert from ./ssl (see docker-compose.prod.yml:
# `- ./ssl:/etc/nginx/ssl:ro`), NOT the live /etc/letsencrypt path. So a renewal is
# only effective once the new pem is copied into ./ssl and nginx reloads. certbot
# runs every deploy hook on every successful renewal, so this fires whenever ANY
# cert renews — the cp is idempotent and the reload is cheap.
#
# poe maps to the UNPREFIXED names (nginx.conf: ssl_certificate /etc/nginx/ssl/fullchain.pem).
set -e
SSL="/opt/catcoin-backend/ssl"
cp /etc/letsencrypt/live/poe.catcoin.in/fullchain.pem "$SSL/fullchain.pem"
cp /etc/letsencrypt/live/poe.catcoin.in/privkey.pem  "$SSL/privkey.pem"
docker exec catcoin_nginx nginx -s reload
