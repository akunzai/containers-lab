# PostgreSQL 資料庫

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## 使用方式

> `podman-compose` 指令必須要在 `compose.yml` 所在的目錄下執行
>
> 可透過建立 `compose.override.yml` 來擴展 `compose.yml` 組態
>
> 還可以利用 [COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file) 環境變數指定多個組態來擴展服務配置

```sh
# 啟動並執行完整應用
podman-compose up

# 在背景啟動並執行完整應用
podman-compose up -d

# 顯示記錄
podman-compose logs

# 持續顯示記錄
podman-compose logs -f

# 關閉應用
podman-compose down

# 如果需要使用網頁介面管理資料庫的話
COMPOSE_FILE=compose.yml:compose.dbgate.yml podman-compose up -d
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 5432: Postgres

## [啟用 TLS 加密連線](https://www.postgresql.org/docs/current/ssl-tcp.html)

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
```

> 如果 `postgres` 伺服器支援而且不是使用 unix socket 方式連線的話，用戶端[預設會偏好使用 TLS 加密連線](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNECT-SSLMODE)

```sh
# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose up -d

# 確認 TLS 加密連線
podman-compose exec postgres bash -c 'psql -h localhost -U $POSTGRES_USER -c "SELECT * FROM pg_stat_ssl;"'
```

## 初始化資料庫

將資料庫匯出檔 `*.sql` 或 `*.sql.gz` 掛載於 `postgres` 容器的 `/docker-entrypoint-initdb.d` 目錄下即可

> 只有在初始化資料庫(第一次建立)時會自動匯入

## 管理資料庫

以下示範使用 `postgres` 容器本身的工具來管理資料庫

> 執行前請先啟動資料庫服務

```sh
# 進入容器的 Bash Shell
podman-compose exec postgres bash

# 完整備份指定資料庫
pg_dump -U $POSTGRES_USER --create sample | gzip > backup.sql.gz

# 完整備份所有資料庫
pg_dumpall -U $POSTGRES_USER | gzip > backup.sql.gz

# 匯入 SQL 備份檔至資料庫
cat backup.sql | psql -U $POSTGRES_USER postgres

# 匯入壓縮的 SQL 備份檔至資料庫
gzip -dc backup.sql.gz | psql -U $POSTGRES_USER
```
