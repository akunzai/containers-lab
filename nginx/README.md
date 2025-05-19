# Nginx 網頁伺服器

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟網站
npx open-cli http://localhost:8080
```

## [啟用 HTTPS 連線](https://nginx.org/en/docs/http/configuring_https_servers.html)

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `www.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkcert -cert-file ./cert.pem -key-file ./key.pem '*.dev.local' localhost

# 產生 Podman secrets
podman secret create --replace dev.local.key ./key.pem
podman secret create --replace dev.local.crt ./cert.pem

# 產生用於 Diffie–Hellman 演算法的密鑰
openssl dhparam -out ./dhparam.pem 2048

# 啟用 TLS 加密連線
podman-compose -f compose.yml -f compose.tls.yml up -d

# 確認已正確啟用
curl -v 'https://www.dev.local:8443'
```
