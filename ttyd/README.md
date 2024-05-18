# [TTYd](終端機網頁伺服器)

用來存取終端機介面的網頁伺服器

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## Getting Started

```sh
# 下載所需的容器映像檔
docker compose pull

# 在背景啟動並執行完整應用
docker compose up -d

# 開啟終端機網頁介面
open http://localhost:7681
```

## [啟用 TLS 加密連線](https://github.com/tsl0922/ttyd/wiki/SSL-Usage)

建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `tty.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkdir -p ../.secrets
mkcert -cert-file ../.secrets/cert.pem -key-file ../.secrets/key.pem '*.dev.local'

# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml docker compose up -d

# 確認已正確啟用
curl -v 'https://tty.dev.local:7681'
```
