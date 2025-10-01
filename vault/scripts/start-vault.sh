#!/bin/sh
set -u

# Start Vault server in the background
echo "[start-vault] Starting Vault server..."
vault server -config=/vault/config/vault.hcl &
VAULT_PID=$!

# Wait for Vault API to become ready
echo "[start-vault] Waiting for Vault to be ready..."
while true; do
  STATUS=$(vault status 2>&1)
  if echo "$STATUS" | grep -q "Seal Type"; then
    echo "[start-vault] Vault API is ready"
    break
  fi
  sleep 2
done

# Check if Vault has been initialized
if ! vault status | grep -q 'Initialized.*true'; then
  echo "[start-vault] Vault not initialized, initializing..."

  # Initialize Vault (1 key share, threshold 1 - dev/lab use only)
  vault operator init -key-shares=1 -key-threshold=1 > /tmp/vault-init.txt

  # Extract unseal key and root token
  UNSEAL_KEY=$(grep 'Unseal Key 1:' /tmp/vault-init.txt | awk '{print $NF}')
  ROOT_TOKEN=$(grep 'Initial Root Token:' /tmp/vault-init.txt | awk '{print $NF}')

  echo "[start-vault] Vault initialized successfully"
  echo "[start-vault] Unseal Key: $UNSEAL_KEY"
  echo "[start-vault] Root Token: $ROOT_TOKEN"
  echo ""
  echo "[start-vault] IMPORTANT: Save these credentials securely!"
  echo "[start-vault] For convenience in development, saving to /vault/file/.vault-keys"

  # Save to persistent volume (dev/lab convenience only - never do this in production)
  cat > /vault/file/.vault-keys <<EOF
VAULT_UNSEAL_KEY=$UNSEAL_KEY
VAULT_ROOT_TOKEN=$ROOT_TOKEN
EOF
  chmod 600 /vault/file/.vault-keys

  # Unseal Vault
  echo "[start-vault] Unsealing Vault..."
  vault operator unseal "$UNSEAL_KEY"

  # Log in with root token
  vault login "$ROOT_TOKEN"

  # Enable KV v2 secrets engine
  echo "[start-vault] Enabling KV v2 secrets engine at path 'secret'..."
  vault secrets enable -version=2 -path=secret kv

  # Seed initial sample secrets for application consumption
  echo "[start-vault] Seeding initial sample secrets into secret/app..."
  vault kv put secret/app/postgres.pwd value="lab-secure-pg-pwd-2026"
  vault kv put secret/app/api_key value="vault-api-key-sample-value"

  # Configure AppRole
  sh /vault/scripts/setup-approle.sh
else
  echo "[start-vault] Vault already initialized"

  # Check if unsealing is required
  if vault status | grep -q 'Sealed.*true'; then
    if [ -f /vault/file/.vault-keys ]; then
      echo "[start-vault] Unsealing Vault..."
      # shellcheck source=/dev/null
      . /vault/file/.vault-keys
      vault operator unseal "$VAULT_UNSEAL_KEY"
    else
      echo "[start-vault] ERROR: Vault is sealed but no .vault-keys found!"
      exit 1
    fi
  else
    echo "[start-vault] Vault is already unsealed"
  fi
fi

echo "[start-vault] Vault is ready!"

# Keep server process running
wait "$VAULT_PID"
