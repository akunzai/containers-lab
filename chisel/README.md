# [Chisel](https://github.com/jpillora/chisel) HTTP 隧道伺服器

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 建立遠端至本地的 TCP 連線通道(反向)
# 在遠端伺服器監聽 5000 埠，連到本地網路的 whoami 容器
podman-compose run --rm chisel-client client http://chisel-server:8080 R:5000:whoami:2001

# 建立本地至遠端的 TCP 連線通道
# 在本機監聽 3000 埠，連到遠端網路的 whoami 容器
podman-compose run --rm -p 127.0.0.1:3000:3000 chisel-client client http://chisel-server:8080 3000:whoami:2001
```

## 建立 TLS 加密連線

### 建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `*.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生伺服器 TLS 憑證
mkcert -cert-file ./cert.pem -key-file ./key.pem '*.dev.local' localhost
# 產生用戶端 TLS 憑證
mkcert -client -cert-file ./client-cert.pem -key-file ./client-key.pem 'client'

# 產生 Podman secrets
podman secret create --replace dev.local.key ./key.pem
podman secret create --replace dev.local.crt ./cert.pem
podman secret create --replace client.key ./client-key.pem
podman secret create --replace client.crt ./client-cert.pem

# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose up -d

# 測試加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml \
  podman-compose run --rm chisel-client client \
  --tls-key=/run/secrets/client.key \
  --tls-cert=/run/secrets/client.crt \
  https://tunnel.dev.local:8443 3000:whoami:2001
```
