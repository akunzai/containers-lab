# [Keycloak](https://www.keycloak.org/) 身分認證與存取管理系統

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 下載所需的容器映像檔
podman-compose pull

# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟管理介面, 預設的帳號與密碼皆為 admin
npx open-cli http://localhost:8080
```

## [啟用 HTTPS 連線](https://www.keycloak.org/server/enabletls)

### 建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `auth.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkcert -cert-file ./cert.pem -key-file ./key.pem '*.dev.local' localhost

# 產生 Podman secrets
podman secret create --replace dev.local.key ./key.pem
podman secret create --replace dev.local.crt ./cert.pem

# 啟用 TLS 加密連線
podman-compose -f compose.yml -f compose.tls.yml up -d

# 確認已正確啟用
curl -v 'https://auth.dev.local:8443'
```

## 匯入與匯出

如果要匯出現有 Keycloak 的所有配置的話

```sh
podman-compose exec keycloak bin/kc.sh export --dir /opt/keycloak/data/export/
```

如果要匯入 Keycloak 配置的話, 請將檔案放置在專案目錄的 [./import](./import/) 目錄下，在啟動 keycloak 容器時便會自動匯入(會略過已存在的 realm)
