# Redis 開發環境 for Docker

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)

## 運行開發環境

> `docker-compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行
>
> 可透過建立 `docker-compose.override.yml` 來擴展 `docker-compose.yml` 組態
>
> 還可以利用 [COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file) 環境變數指定多個組態來擴展服務配置

```sh
# 啟動並執行完整應用
docker-compose up

# 在背景啟動並執行完整應用
docker-compose up -d

# 顯示記錄
docker-compose logs

# 持續顯示記錄
docker-compose logs -f

# 關閉應用
docker-compose down

# 顯示所有啟動中的容器
docker ps
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 6379: Redis

## 建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `*.example.test` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkdir -p tls
mkcert -cert-file tls/cert.pem -key-file tls/key.pem '*.example.test'

# redis 需要額外指定簽發根憑證
cp -v "$(mkcert -CAROOT)/rootCA.pem" tls/ca.pem
```

### [啟用 TLS 加密連線](https://redis.io/topics/encryption)

```sh
# 啟用 TLS 加密連線
COMPOSE_FILE=docker-compose.yml:docker-compose.tls.yml docker-compose up -d

# 確認已正確啟用
COMPOSE_FILE=docker-compose.yml:docker-compose.tls.yml docker-compose exec redis redis-cli -p 6380 --tls \
    --cert /etc/tls/cert.pem \
    --key /etc/tls/key.pem \
    --cacert /etc/tls/ca.pem info
```
