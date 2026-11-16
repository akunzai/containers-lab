#!/bin/sh
# Entry point of the vault service. Runs as root only long enough to copy the bind-mounted TLS key
# (owned by whoever created it on the host, mode 600) to a directory the vault user owns, then
# hands over to the image's own entrypoint, which drops to the vault user.
set -eu

src="${VAULT_TLS_SOURCE:-/vault/tls-source}"
for f in tls.crt tls.key; do
  [ -s "$src/$f" ] || {
    echo "start-server: $src/$f is missing; run scripts/tls-certs.sh first (README.md)" >&2
    exit 1
  }
done
install -d -o vault -g vault -m 0700 /vault/tls /vault/audit
install -o vault -g vault -m 0444 "$src/tls.crt" /vault/tls/tls.crt
install -o vault -g vault -m 0400 "$src/tls.key" /vault/tls/tls.key

exec docker-entrypoint.sh server
