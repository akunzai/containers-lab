# [容器映像儲存庫](https://docs.docker.com/registry/)

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## 使用方式

> `podman-compose` 指令必須要在 `compose.yml` 所在的目錄下執行

可透過建立 `compose.override.yml` 來擴展 `compose.yml` 組態

```sh
# 啟動並執行完整應用(若配置有異動會自動重建容器)
podman-compose up

# 在背景啟動並執行完整應用
podman-compose up -d

# 顯示記錄
podman-compose logs

# 持續顯示記錄
podman-compose logs -f

# 關閉應用
podman-compose down
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 5000: HTTP

## [部署](https://distribution.github.io/distribution/about/deploying/)

## 建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `*.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkdir -p ../.secrets
mkcert -cert-file ../.secrets/cert.pem -key-file ../.secrets/key.pem '*.dev.local'

# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose up -d

# 確認已正確啟用
curl -kv 'https://registry.dev.local:8443'
```

## 限制存取

> 應避免未限制存取就將自建的映像檔伺服器部署在公開的網路上

```sh
# 產生可登入存取 Registry 的帳號與密碼
podman run \
  --entrypoint htpasswd \
  httpd:2 -Bbn testuser testpassword >> ../.secrets/htpasswd

# 啟用限制存取
COMPOSE_FILE=compose.yml:compose.auth.yml podman-compose up -d

# 登入自建的 Registry
podman login localhost:5000
```

## 測試

```sh
# 上傳映像檔專案至自建的 Registry
podman pull hello-world
podman tag hello-world localhost:5000/hello-world
podman push localhost:5000/hello-world

# 列出 Registry 上的所有映像檔專案
crane catalog localhost:5000
```
