# [容器映像儲存庫](https://docs.docker.com/registry/)

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d
```

## [部署](https://distribution.github.io/distribution/about/deploying/)

## 建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `*.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkcert -cert-file ./cert.pem -key-file ./key.pem '*.dev.local' localhost

# 產生 Podman secrets
podman secret create --replace dev.local.key ./key.pem
podman secret create --replace dev.local.crt ./cert.pem

# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose up -d

# 確認已正確啟用
curl -kv 'https://registry.dev.local:8443'
```

## 限制存取

> 應避免未限制存取就將自建的映像檔伺服器部署在公開的網路上

```sh
# 產生可登入存取 Registry 的帳號與密碼
podman run --entrypoint htpasswd httpd:2 -Bbn admin "$(openssl rand -base64 16)" | podman secret create --replace registry.auth.htpasswd -

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
