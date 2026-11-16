# Single-node Vault for the lab.
# https://developer.hashicorp.com/vault/docs/configuration

# No web UI: with the root token revoked there is no token to log in with that should be pasted
# into a browser. Manage secrets with the CLI as README.md shows.
ui = false

# https://developer.hashicorp.com/vault/docs/configuration/storage/filesystem
storage "file" {
  path = "/vault/file"
}

# HTTPS only. start-server.sh copies the certificate and key here with the vault user's ownership.
# https://developer.hashicorp.com/vault/docs/configuration/listener/tcp
listener "tcp" {
  address         = "0.0.0.0:8200"
  tls_cert_file   = "/vault/tls/tls.crt"
  tls_key_file    = "/vault/tls/tls.key"
  tls_min_version = "tls12"
}

api_addr = "https://vault:8200"

# mlock off, and therefore no IPC_LOCK capability for the container. HashiCorp recommends keeping
# mlock unless the host has no swap or only encrypted swap. This lab keeps its unseal key in a
# volume on the same disk, so anyone able to read swap can read the key anyway: mlock would
# protect nothing here while pinning the whole Vault binary in memory. Revisit this together with
# the unseal method in any real deployment (README.md, "mlock").
# https://developer.hashicorp.com/vault/docs/configuration#disable_mlock
disable_mlock = true

# Default and ceiling for tokens not given their own TTL; the AppRole tokens set theirs in init.sh.
default_lease_ttl = "1h"
max_lease_ttl     = "768h"

# Break-glass only (README.md): since Vault 2.0, sys/generate-root needs a token as well as the
# unseal key, and the root token has been revoked. Uncomment, send SIGHUP, generate a root token,
# then comment it out again and send SIGHUP once more.
# https://developer.hashicorp.com/vault/docs/updates/important-changes
# enable_unauthenticated_access = ["generate-root"]
