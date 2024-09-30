# .NET 執行環境

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟網站
npx open-cli http://localhost:8080
```

## [啟用 TLS 加密連線](https://github.com/dotnet/dotnet-docker/blob/main/samples/host-aspnetcore-https.md)

建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `www.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkcert -cert-file ./cert.pem -key-file ./key.pem '*.dev.local' localhost

# 產生 Podman secrets
podman secret exists dev.local.key || podman secret create dev.local.key ./key.pem
podman secret exists dev.local.crt || podman secret create dev.local.crt ./cert.pem

# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose up -d

# 確認已正確啟用
curl -v 'https://www.dev.local:8443'
```

## 疑難排解

### [建置不同系統架構的 Docker 映像](https://developers.redhat.com/articles/2023/11/03/how-build-multi-architecture-container-images#podman)

```sh
# 透過 podman-compose 建置指定系統架構的映像
podman-compose --podman-build-args='--platform=linux/amd64' build

# 透過 podman 建置多系統架構的映像
podman manifest create -a dotnet:demo
podman build --platform=linux/amd64,linux/arm64 --manifest dotnet:demo ./demo
```
