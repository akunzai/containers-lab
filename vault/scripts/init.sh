#!/bin/sh
# Bootstraps and feeds the lab's Vault. Runs in the hashicorp/vault image as the vault-init
# service, as root. Never prints a token, key or secret value.
#
#   init.sh up       first run: init (1 key share), unseal, configure audit, KV, AppRole and
#                    policies, seed random demo secrets, revoke the root token, deliver.
#                    Later runs: unseal if sealed, then deliver.
#   init.sh reconfigure
#                    break-glass: generate a root token from the unseal key, re-apply policies,
#                    AppRoles and the delivery token from secrets.manifest, revoke the root token.
#                    Needs enable_unauthenticated_access in vault.hcl (README.md, "Break-glass").
#   init.sh deliver  write each application's role_id and a response-wrapped, single-use
#                    secret_id where its Vault Agent picks them up.
#   init.sh policy APP
#                    print the policy APP gets, from secrets.manifest.
set -eu

# shellcheck source=vault/scripts/vault-lib.sh
. "$(dirname "$0")/vault-lib.sh"

STATE_DIR="${VAULT_STATE_DIR:-/vault/state}"
APPROLE_ROOT="${VAULT_APPROLE_ROOT:-/approle}"
# "app=uid:gid ..." for every application whose credentials this container delivers: the owner of
# its delivery directory, and of the files written there.
AGENT_USERS="${VAULT_AGENT_USERS:-}"
# How long a delivered secret_id stays unwrappable, and how long it lives once unwrapped. Vault
# Agent unwraps it within seconds of starting; anything left over is useless after this.
WRAP_TTL="${VAULT_WRAP_TTL:-5m}"
SECRET_ID_TTL="${VAULT_SECRET_ID_TTL:-10m}"
# AppRole tokens are periodic: Vault Agent renews them for as long as it runs, and one it stops
# renewing dies within this period. A restarted agent needs a fresh delivery.
TOKEN_PERIOD="${VAULT_APP_TOKEN_PERIOD:-1h}"
# The delivery token is periodic too; every deliver renews it.
ISSUER_PERIOD="${VAULT_ISSUER_TOKEN_PERIOD:-768h}"

log() { printf '[vault-init] %s\n' "$*"; }
die() {
  printf '[vault-init] ERROR: %s\n' "$*" >&2
  exit 1
}

vl_validate

# vault status: 0 unsealed, 2 sealed, 1 unreachable.
wait_for_api() {
  i=0
  while :; do
    rc=0
    vault status >/dev/null 2>&1 || rc=$?
    [ "$rc" -ne 1 ] && return 0
    i=$((i + 1))
    [ "$i" -lt 60 ] || die "Vault at $VAULT_ADDR did not answer within 60s"
    sleep 1
  done
}

is_initialized() { vault status -format=json 2>/dev/null | grep -q '"initialized": *true'; }
is_sealed() { vault status -format=json 2>/dev/null | grep -q '"sealed": *true'; }

ensure_audit() {
  if vault audit list 2>/dev/null | grep -q '^file/'; then
    return
  fi
  # Vault refuses every request no enabled audit device can log, so a full disk here stops Vault.
  # https://developer.hashicorp.com/vault/docs/audit
  # https://developer.hashicorp.com/vault/docs/audit/file
  vault audit enable -path=file file file_path=/vault/audit/audit.log >/dev/null
  log "enabled the file audit device"
}

ensure_kv() {
  vault secrets list 2>/dev/null | grep -q "^$VAULT_KV_MOUNT/" ||
    vault secrets enable -path="$VAULT_KV_MOUNT" -version=2 kv >/dev/null
}

ensure_approle() {
  vault auth list 2>/dev/null | grep -q '^approle/' || vault auth enable approle >/dev/null
  for app in $(vl_apps); do
    vl_policy "$app" | vault policy write "$app" - >/dev/null
    # https://developer.hashicorp.com/vault/api-docs/auth/approle#create-update-approle
    vault write "auth/approle/role/$app" \
      token_policies="$app" \
      token_type=service \
      token_period="$TOKEN_PERIOD" \
      secret_id_num_uses=1 \
      secret_id_ttl="$SECRET_ID_TTL" \
      bind_secret_id=true >/dev/null
    log "policy and AppRole for $app"
  done
}

# The delivery token outlives root, so deliver never needs root. It can only mint wrapped
# secret_ids (vl_issuer_policy).
ensure_issuer_token() {
  vl_issuer_policy | vault policy write secret-id-issuer - >/dev/null
  if [ -s "$STATE_DIR/issuer-token" ] &&
    VAULT_TOKEN="$(cat "$STATE_DIR/issuer-token")" vault token lookup >/dev/null 2>&1; then
    return
  fi
  (
    umask 077
    vault token create -orphan -policy=secret-id-issuer -period="$ISSUER_PERIOD" \
      -display-name=secret-id-issuer -field=token >"$STATE_DIR/issuer-token"
  )
  log "wrote a new delivery token to $STATE_DIR/issuer-token"
}

# Every manifest name from VAULT_SEED_<NAME> when set, otherwise a random 64-byte value. Values
# travel on stdin (NAME=-), never on a command line.
seed() {
  vl_entries | awk '{ print $1 }' | sort -u | while read -r entry; do
    verb='put'
    vl_entries | awk -v e="$entry" '$1 == e { print $2 }' | while read -r name; do
      if eval "[ -n \"\${VAULT_SEED_$name+set}\" ]"; then
        eval "printf '%s' \"\${VAULT_SEED_$name}\""
      else
        head -c 64 /dev/urandom | base64 | tr '+/' '-_' | tr -d '=\n'
      fi | vault kv "$verb" -mount="$VAULT_KV_MOUNT" "$entry" "$name=-" >/dev/null
      verb='patch'
    done
    log "seeded $VAULT_KV_MOUNT/$entry"
  done
}

agent_user() {
  for pair in $AGENT_USERS; do
    [ "${pair%%=*}" = "$1" ] && {
      printf '%s' "${pair#*=}"
      return 0
    }
  done
  return 1
}

deliver() {
  [ -s "$STATE_DIR/issuer-token" ] || die "no delivery token in $STATE_DIR; Vault was never configured"
  VAULT_TOKEN="$(cat "$STATE_DIR/issuer-token")"
  export VAULT_TOKEN
  vault token renew >/dev/null
  for app in $(vl_apps); do
    dir="$APPROLE_ROOT/$app"
    [ -d "$dir" ] || continue
    [ ! -L "$dir" ] || die "$dir is a symlink; refusing to deliver into it"
    owner="$(agent_user "$app")" || die "no uid:gid for $app in VAULT_AGENT_USERS"
    chown "$owner" "$dir"
    chmod 0700 "$dir"
    # The agent's uid owns this directory (it deletes secret-id after reading it), so root never
    # writes into it: a symlink planted there would redirect a root write anywhere. The files are
    # written as the agent's uid. Each value is assigned first so that set -e stops on a failed
    # vault call; printf is a builtin, so values never reach a command line.
    role_id="$(vault read -field=role_id "auth/approle/role/$app/role-id")"
    wrapped="$(vault write -f -wrap-ttl="$WRAP_TTL" -field=wrapping_token "auth/approle/role/$app/secret-id")"
    # shellcheck disable=SC2016 # $1 expands in the inner shell
    printf '%s' "$role_id" | su-exec "$owner" sh -c 'umask 077; rm -f "$1"; cat >"$1"' _ "$dir/role-id"
    # shellcheck disable=SC2016
    printf '%s' "$wrapped" | su-exec "$owner" sh -c 'umask 077; rm -f "$1"; cat >"$1"' _ "$dir/secret-id"
    unset role_id wrapped
    log "delivered a wrapped secret_id for $app (valid $WRAP_TTL)"
  done
  unset VAULT_TOKEN
}

unseal() {
  [ -s "$STATE_DIR/unseal-key" ] || die "Vault is sealed and $STATE_DIR/unseal-key is missing"
  # @file keeps the key off the command line; sys/unseal is unauthenticated.
  vault write sys/unseal key=@"$STATE_DIR/unseal-key" >/dev/null
  log "unsealed"
}

configure() {
  vl_admin_policy | vault policy write secret-admin - >/dev/null
  ensure_audit
  ensure_kv
  ensure_approle
  ensure_issuer_token
}

json_field() { sed -n "s/.*\"$1\": *\"\([^\"]*\)\".*/\1/p"; }

# Root token from the unseal key, decoded with a one-time password that never leaves this shell.
# Since Vault 2.0 sys/generate-root needs a token too, unless vault.hcl lists it in
# enable_unauthenticated_access.
# https://developer.hashicorp.com/vault/docs/troubleshoot/generate-root-token
# https://developer.hashicorp.com/vault/docs/updates/important-changes
generate_root() {
  [ -s "$STATE_DIR/unseal-key" ] || die "$STATE_DIR/unseal-key is missing"
  vault operator generate-root -cancel >/dev/null 2>&1 || true
  attempt="$(vault operator generate-root -init -format=json 2>/dev/null)" ||
    die "generate-root refused; enable it in vault.hcl and send SIGHUP first (README.md)"
  nonce="$(printf '%s\n' "$attempt" | json_field nonce)"
  otp="$(printf '%s\n' "$attempt" | json_field otp)"
  # The OTP and the encoded token reach this container's process list for an instant; nothing else
  # runs in vault-init.
  encoded="$(vault operator generate-root -nonce="$nonce" -format=json - <"$STATE_DIR/unseal-key" | json_field encoded_root_token)"
  VAULT_TOKEN="$(vault operator generate-root -decode="$encoded" -otp="$otp")"
  unset attempt nonce otp encoded
  [ -n "$VAULT_TOKEN" ] || die "could not decode the generated root token"
  export VAULT_TOKEN
  log "generated a root token for this run only"
}

bootstrap() {
  # One share, kept in the state volume beside Vault: a lab has nobody to hand shares to. This is
  # what a real deployment must not copy (README.md, "Unseal").
  init="$(vault operator init -key-shares=1 -key-threshold=1 -format=json)"
  (
    umask 077
    printf '%s\n' "$init" | awk '/"unseal_keys_b64"/ { getline; gsub(/[ ",]/, ""); printf "%s", $0; exit }' >"$STATE_DIR/unseal-key"
  )
  VAULT_TOKEN="$(printf '%s\n' "$init" | sed -n 's/.*"root_token": *"\([^"]*\)".*/\1/p')"
  unset init
  [ -s "$STATE_DIR/unseal-key" ] && [ -n "$VAULT_TOKEN" ] || die "could not read vault operator init output"
  export VAULT_TOKEN
  log "initialized (1 key share, lab only)"
  unseal
  configure
  seed
  # Stands in for per-person accounts bound to secret-admin in a real deployment.
  (
    umask 077
    vault token create -orphan -policy=secret-admin -period=768h -display-name=lab-secret-admin \
      -field=token >"$STATE_DIR/admin-token"
  )
  # https://developer.hashicorp.com/vault/docs/concepts/tokens#root-tokens
  vault token revoke -self >/dev/null
  unset VAULT_TOKEN
  log "revoked the root token; break-glass is vault operator generate-root (README.md)"
}

case "${1:-}" in
  up)
    wait_for_api
    if ! is_initialized; then
      bootstrap
    elif is_sealed; then
      unseal
    fi
    deliver
    ;;
  reconfigure)
    wait_for_api
    is_sealed && die "Vault is sealed; run init.sh up"
    unset VAULT_TOKEN
    generate_root
    configure
    vault token revoke -self >/dev/null
    unset VAULT_TOKEN
    log "reconfigured from secrets.manifest and revoked the root token"
    deliver
    ;;
  deliver)
    wait_for_api
    is_sealed && die "Vault is sealed; run init.sh up"
    deliver
    ;;
  policy) vl_policy "${2:?app}" ;;
  *)
    echo "usage: init.sh up|reconfigure|deliver|policy APP" >&2
    exit 2
    ;;
esac
