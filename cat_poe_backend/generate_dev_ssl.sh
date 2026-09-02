#!/usr/bin/env bash
# Self-signed TLS for local / staging Docker only. Replace with real certs (e.g. Let's Encrypt) in production.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SSL_DIR="$ROOT/ssl"
mkdir -p "$SSL_DIR"
openssl req -x509 -nodes -days 825 -newkey rsa:2048 \
  -keyout "$SSL_DIR/privkey.pem" \
  -out "$SSL_DIR/fullchain.pem" \
  -subj "/CN=poe.catcoin.in" \
  -addext "subjectAltName=DNS:poe.catcoin.in,DNS:localhost,IP:127.0.0.1"
echo "Wrote $SSL_DIR/fullchain.pem and privkey.pem (self-signed; browsers will warn)."
