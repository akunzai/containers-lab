#!/bin/sh
set -u

# 等待 vault 準備好 (unsealed)
echo "[start-agent] Waiting for Vault to be ready and unsealed..."
while true; do
  STATUS=$(vault status 2>&1)
  if echo "$STATUS" | grep -q "Sealed.*false"; then
    echo "[start-agent] Vault is ready and unsealed"
    break
  fi
  sleep 2
done

# 等待 AppRole 憑證可用
echo "[start-agent] Waiting for AppRole credentials..."
while true; do
  if [ -f /vault/approle/role-id ] && [ -f /vault/approle/secret-id ]; then
    echo "[start-agent] AppRole credentials found"
    break
  fi
  sleep 2
done

echo "[start-agent] Starting Vault Agent..."
exec vault agent -log-level=info -config=/vault/config/agent.hcl
