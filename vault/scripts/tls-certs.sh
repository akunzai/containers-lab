#!/usr/bin/env bash
# Issues a throwaway CA for this lab and a Vault server certificate signed by it, into DIR
# (default: certs/ beside compose.yml): ca.crt, ca.key, tls.crt, tls.key. Only ca.crt, tls.crt
# and tls.key are mounted into containers, file by file; ca.key never leaves the host directory.
# Rerun to reissue the server certificate under the same CA.
#
#   scripts/tls-certs.sh [DIR [SAN...]]     default SANs: vault localhost 127.0.0.1
set -euo pipefail

dir="${1:-$(cd "$(dirname "$0")/.." && pwd)/certs}"
shift || true
sans=("$@")
[[ ${#sans[@]} -gt 0 ]] || sans=(vault localhost 127.0.0.1)

san_list=''
for san in "${sans[@]}"; do
  if [[ "$san" =~ ^[0-9.]+$ || "$san" == *:* ]]; then
    san_list+="${san_list:+,}IP:$san"
  elif [[ "$san" =~ ^[A-Za-z0-9*]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]; then
    san_list+="${san_list:+,}DNS:$san"
  else
    printf 'tls-certs: not a DNS name or IP address: %s\n' "$san" >&2
    exit 2
  fi
done

mkdir -p "$dir"
umask 077
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
# openssl reports progress on stderr; show it only when a step fails.
quiet() { "$@" 2>"$work/openssl.err" || { cat "$work/openssl.err" >&2; return 1; }; }

if [[ ! -s "$dir/ca.crt" || ! -s "$dir/ca.key" ]]; then
  quiet openssl req -x509 -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
    -keyout "$dir/ca.key" -out "$dir/ca.crt" -days 3650 -subj '/CN=Vault lab CA' \
    -addext 'basicConstraints=critical,CA:TRUE,pathlen:0' \
    -addext 'keyUsage=critical,keyCertSign,cRLSign'
fi

quiet openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
  -keyout "$work/tls.key" -out "$work/tls.csr" -subj "/CN=${sans[0]}"
cat >"$work/ext.cnf" <<EXT
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=serverAuth
subjectAltName=$san_list
EXT
quiet openssl x509 -req -in "$work/tls.csr" -CA "$dir/ca.crt" -CAkey "$dir/ca.key" \
  -CAcreateserial -CAserial "$work/ca.srl" -days 397 -extfile "$work/ext.cnf" -out "$work/tls.crt"
mv "$work/tls.key" "$dir/tls.key"
mv "$work/tls.crt" "$dir/tls.crt"
# Certificates are public; keys stay 600. start-server.sh copies tls.key for the vault user.
chmod 644 "$dir/ca.crt" "$dir/tls.crt"
printf 'tls-certs: %s/tls.crt for %s\n' "$dir" "$san_list" >&2
