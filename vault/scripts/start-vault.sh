#!/bin/sh
set -u

# 啟動 Vault 伺服器在背景
echo "[start-vault] Starting Vault server..."
vault server -config=/vault/config/vault.hcl &
VAULT_PID=$!

# 等待 Vault API 準備好
echo "[start-vault] Waiting for Vault to be ready..."
while true; do
  STATUS=$(vault status 2>&1)
  if echo "$STATUS" | grep -q "Seal Type"; then
    echo "[start-vault] Vault API is ready"
    break
  fi
  sleep 2
done

# 檢查是否已初始化
if ! vault status | grep -q 'Initialized.*true'; then
  echo "[start-vault] Vault not initialized, initializing..."

  # 初始化 Vault (1 個 key share, threshold 1 - 僅供開發/測試使用)
  vault operator init -key-shares=1 -key-threshold=1 > /tmp/vault-init.txt

  # 提取 unseal key 和 root token
  UNSEAL_KEY=$(grep 'Unseal Key 1:' /tmp/vault-init.txt | awk '{print $NF}')
  ROOT_TOKEN=$(grep 'Initial Root Token:' /tmp/vault-init.txt | awk '{print $NF}')

  echo "[start-vault] Vault initialized successfully"
  echo "[start-vault] Unseal Key: $UNSEAL_KEY"
  echo "[start-vault] Root Token: $ROOT_TOKEN"
  echo ""
  echo "[start-vault] IMPORTANT: Save these credentials securely!"
  echo "[start-vault] For convenience in development, saving to /vault/file/.vault-keys"

  # 儲存到 persistent volume (僅供開發使用！正式環境請勿這樣做)
  cat > /vault/file/.vault-keys <<EOF
VAULT_UNSEAL_KEY=$UNSEAL_KEY
VAULT_ROOT_TOKEN=$ROOT_TOKEN
EOF
  chmod 600 /vault/file/.vault-keys

  # Unseal Vault
  echo "[start-vault] Unsealing Vault..."
  vault operator unseal "$UNSEAL_KEY"

  # 登入
  vault login "$ROOT_TOKEN"

  # 啟用 KV v2 secrets engine
  echo "[start-vault] Enabling KV v2 secrets engine at path 'secret'..."
  vault secrets enable -version=2 -path=secret kv

  # 設定 AppRole
  sh /vault/scripts/setup-approle.sh
else
  echo "[start-vault] Vault already initialized"

  # 檢查是否需要 unseal
  if vault status | grep -q 'Sealed.*true'; then
    if [ -f /vault/file/.vault-keys ]; then
      echo "[start-vault] Unsealing Vault..."
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

# 保持進程運行
wait $VAULT_PID
