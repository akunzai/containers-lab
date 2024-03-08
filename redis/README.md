# Redis 鍵值資料庫

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## 使用方式

> `docker compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行
>
> 可透過建立 `docker-compose.override.yml` 來擴展 `docker-compose.yml` 組態
>
> 還可以利用 [COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file) 環境變數指定多個組態來擴展服務配置

```sh
# 啟動並執行完整應用
docker compose up

# 在背景啟動並執行完整應用
docker compose up -d

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

- 6379: Redis

## 複寫資料庫

```sh
# 啟動另一個配置好的 redis2 容器以複寫原有容器的資料庫
docker compose up -d redis2

# 複寫 redis 容器的資料庫
docker compose exec redis2 redis-cli replicaof redis 6379

# 等複寫完成後取消資料庫複寫
docker compose exec redis2 redis-cli replicaof no one

# 最後再將 redis2 更名為 redis 即可
```

## [啟用 TLS 加密連線](https://redis.io/topics/encryption)

### 建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `*.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkdir -p certs
mkcert -cert-file certs/cert.pem -key-file certs/key.pem '*.dev.local'

# redis 需要額外指定簽發根憑證
cp -v "$(mkcert -CAROOT)/rootCA.pem" certs/ca.pem
```

```sh
# 啟用 TLS 加密連線
COMPOSE_FILE=docker-compose.yml:docker-compose.tls.yml docker compose up -d

# 確認已正確啟用
COMPOSE_FILE=docker-compose.yml:docker-compose.tls.yml docker compose exec redis redis-cli -p 6380 --tls \
    --cert /usr/local/etc/redis/cert.pem \
    --key /usr/local/etc/redis/key.pem \
    --cacert /usr/local/etc/redis/ca.pem info
```
