#!/bin/sh
set -u

echo "[setup-approle] Setting up AppRole for vault-agent..."

# Enable AppRole auth method
vault auth enable approle 2>/dev/null || echo "[setup-approle] AppRole already enabled"

# Create policy allowing reading secret/data/app/* and listing secret/metadata/app
cat > /tmp/agent-policy.hcl <<EOF
# Allow tokens to look up their own properties
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow tokens to renew themselves
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow reading secrets under secret/data/app/
path "secret/data/app/*" {
  capabilities = ["read"]
}

# Allow listing secrets under secret/metadata/app/
path "secret/metadata/app/*" {
  capabilities = ["list", "read"]
}

path "secret/metadata/app" {
  capabilities = ["list", "read"]
}
EOF

vault policy write agent-policy /tmp/agent-policy.hcl

# Create AppRole
vault write auth/approle/role/agent-role \
  token_ttl=1h \
  token_max_ttl=4h \
  token_policies="agent-policy" \
  bind_secret_id=true \
  secret_id_ttl=0

# Retrieve role-id and secret-id
ROLE_ID=$(vault read -field=role_id auth/approle/role/agent-role/role-id)
SECRET_ID=$(vault write -field=secret_id -f auth/approle/role/agent-role/secret-id)

echo "[setup-approle] AppRole created successfully"
echo "[setup-approle] Role ID: $ROLE_ID"
echo "[setup-approle] Secret ID: $SECRET_ID"
echo ""
echo "[setup-approle] Saving credentials to /vault/approle/"

# Create AppRole volume directory
mkdir -p /vault/approle

# Write role-id and secret-id
echo "$ROLE_ID" > /vault/approle/role-id
echo "$SECRET_ID" > /vault/approle/secret-id
chmod 400 /vault/approle/role-id
chmod 400 /vault/approle/secret-id

echo "[setup-approle] Setup complete!"
