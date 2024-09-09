# [Redis](https://redis.io/) 鍵值資料庫

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 顯示 Redis 伺服器資訊
podman-compose exec redis redis-cli info
```

## 複寫資料庫

```sh
# 啟動另一個配置好的 redis2 容器以複寫原有容器的資料庫
podman-compose up -d redis2

# 複寫 redis 容器的資料庫
podman-compose exec redis2 redis-cli replicaof redis 6379

# 等複寫完成後取消資料庫複寫
podman-compose exec redis2 redis-cli replicaof no one

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
mkcert -cert-file ./cert.pem -key-file ./key.pem '*.dev.local' localhost

# 產生 Podman secrets
podman secret exists dev.local.key || podman secret create dev.local.key ./key.pem
podman secret exists dev.local.crt || podman secret create dev.local.crt ./cert.pem
podman secret exists dev.CA.crt || podman secret create dev.CA.crt

# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose up -d

# 確認已正確啟用
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose exec redis redis-cli -p 6380 --tls \
    --cert /run/secrets/dev.local.crt \
    --key /run/secrets/dev.local.key \
    --cacert /run/secrets/dev.CA.crt info
```
