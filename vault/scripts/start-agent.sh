#!/bin/sh
# Entry point of a vault-agent-<app> service: render this application's agent configuration from
# the manifest, then run Vault Agent in the foreground. Runs as the application's uid, so the files
# it renders (mode 0400) are readable by that uid only.
set -eu

# shellcheck source=vault/scripts/vault-lib.sh
. "$(dirname "$0")/vault-lib.sh"

APP="${VAULT_AGENT_APP:?set VAULT_AGENT_APP}"
SECRETS_DIR="${VAULT_SECRETS_DIR:-/secrets}"
APPROLE_DIR="${VAULT_APPROLE_DIR:-/approle}"

mkdir -p /tmp/agent
vl_agent_config "$APP" "$SECRETS_DIR" "$APPROLE_DIR" "$VAULT_ADDR" "$VAULT_CACERT" >/tmp/agent/agent.hcl
vl_expected "$APP" >/tmp/agent/expected

exec vault agent -log-level=info -config=/tmp/agent/agent.hcl
