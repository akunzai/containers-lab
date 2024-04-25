# [Chisel](https://github.com/jpillora/chisel) HTTP 隧道伺服器

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## 使用方式

> `docker compose` 指令必須要在 `compose.yml` 所在的目錄下執行
>
> 可透過建立 `compose.override.yml` 來擴展 `compose.yml` 組態
>
> 還可以利用 [COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file) 環境變數指定多個組態來擴展服務配置

```sh
# 啟動並執行完整應用
docker compose up

# 在背景啟動並執行完整應用
docker compose up -d

# 在背景啟動並執行指定服務
docker compose up -d chisel-server

# 顯示記錄
docker compose logs

# 持續顯示記錄
docker compose logs -f

# 關閉應用
docker compose down

# 顯示所有啟動中的容器
docker ps
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 8080: HTTP

## 啟用 HTTPS 連線

### 建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `*.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生伺服器 TLS 憑證
mkdir -p ../.secrets
mkcert -cert-file ../.secrets/cert.pem -key-file ../.secrets/key.pem '*.dev.local'

# 產生用戶端 TLS 憑證
mkcert -client -cert-file ../.secrets/client-cert.pem -key-file ../.secrets/client-key.pem 'client'

# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml docker compose up -d

# 測試加密連線
chisel client --tls-key=../.secrets/client-key.pem --tls-cert=../.secrets/client-cert.pem https://tunnel.dev.local 3000:whoami:80
```

## 如何建立 TCP 連線通道

```sh
# 建立遠端至本地的 TCP 連線通道(反向)
# 在遠端伺服器監聽 5000 埠，連到本地網路的 whoami 容器
docker compose run --rm chisel-client client http://chisel-server:8080 R:5000:whoami:80

# 建立本地至遠端的 TCP 連線通道
# 在本機監聽 3000 埠，連到遠端網路的 whoami 容器
docker compose run --rm -p 127.0.0.1:3000:3000 chisel-client client http://chisel-server:8080 3000:whoami:80
```
