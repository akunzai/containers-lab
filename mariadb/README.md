# MariaDB 資料庫

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

# 顯示記錄
docker compose logs

# 持續顯示記錄
docker compose logs -f

# 關閉應用
docker compose down

# 顯示所有啟動中的容器
docker ps

# 如果需要使用網頁介面管理資料庫的話
COMPOSE_FILE=compose.yml:compose.dbgate.yml docker compose up -d
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 3306: MySQL

## [啟用 TLS 加密連線](https://mariadb.com/kb/en/securing-connections-for-client-and-server/)

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `*.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkdir -p ../.secrets
mkcert -cert-file ../.secrets/cert.pem -key-file ../.secrets/key.pem '*.dev.local'
```

> 如果 `mariadb` 伺服器支援加密連線的話，用戶端預設會嘗試使用

```sh
# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml docker compose up -d

# 確認已正確啟用
docker compose exec mariadb mariadb -p -e 'SHOW VARIABLES LIKE "%ssl%";'

# 如果要使用者必須使用加密連線登入的話
docker compose exec mariadb mariadb -p -e 'ALTER USER "alice"@"%" REQUIRE SSL;'
# 也可以反過來取消加密連線的登入限制
docker compose exec mariadb mariadb -p -e 'ALTER USER "alice"@"localhost" REQUIRE NONE;'

# 測試用戶端加密連線
mariadb -h db.dev.local -u root -p -e 'SHOW STATUS LIKE "ssl_version";'
```

## 初始化資料庫

將資料庫匯出檔 `*.sql` 或 `*.sql.gz` 掛載於 `mariadb` 容器的 `/docker-entrypoint-initdb.d` 目錄下即可

> 只有在初始化資料庫(第一次建立)時會自動匯入

## 重設資料庫 root 帳號密碼

> 以下指令執行前請先啟動資料庫服務

```sh
# 進入容器的 Bash Shell
docker compose exec mariadb bash

# 直接重設 root 帳號密碼
mariadb-admin -u root password 'secret'

# 或是透過以下互動程序來設定所有安全性選項
mariadb-secure-installation

# 建立遠端登入的帳號密碼
mariadb -e "CREATE USER root@'%' IDENTIFIED BY 'secret'; FLUSH PRIVILEGES;"

# 更變遠端登入的帳號密碼
mariadb -e "ALTER USER root@'%' IDENTIFIED BY 'secret'; FLUSH PRIVILEGES;"
```

## 管理資料庫

以下示範使用 `mariadb` 容器本身的工具來管理資料庫

> 執行前請先啟動資料庫服務

可以透過設定[認證資訊](https://dev.mysql.com/doc/refman/8.0/en/password-security-user.html)於 `my.cnf` 以簡化認證流程

```sh
# 進入容器的 Bash Shell
docker compose exec mariadb bash

# 完整備份指定資料庫
mariadb-dump --single-transaction --add-drop-database --insert-ignore --databases sample | gzip > backup.sql.gz

# 完整備份所有資料庫
mariadb-dump --single-transaction --add-drop-database --insert-ignore --all-databases | gzip > backup.sql.gz

# 匯入 SQL 備份檔至資料庫
cat backup.sql | mariadb

# 匯入壓縮的 SQL 備份檔至資料庫
gzip -dc backup.sql.gz | mariadb
```
