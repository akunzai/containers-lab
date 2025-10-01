#!/bin/sh
set -u

# Wait for Vault to be ready and unsealed
echo "[start-agent] Waiting for Vault to be ready and unsealed..."
while true; do
  STATUS=$(vault status 2>&1)
  if echo "$STATUS" | grep -q "Sealed.*false"; then
    echo "[start-agent] Vault is ready and unsealed"
    break
  fi
  sleep 2
done

# Wait for AppRole credentials
echo "[start-agent] Waiting for AppRole credentials..."
while true; do
  if [ -f /vault/approle/role-id ] && [ -f /vault/approle/secret-id ]; then
    echo "[start-agent] AppRole credentials found"
    break
  fi
  sleep 2
done

# Clean up previous ready marker if restarting
rm -f /secrets/.ready

echo "[start-agent] Starting Vault Agent..."
exec vault agent -log-level=info -config=/vault/config/agent.hcl
