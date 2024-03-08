# [SQL Server](https://learn.microsoft.com/sql/linux/sql-server-linux-overview) 資料庫

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

# 如果需要使用網頁介面管理資料庫的話
COMPOSE_FILE=docker-compose.yml:docker-compose.adminer.yml docker compose up -d
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 1433: SQL Server

## [啟用 TLS 加密連線](https://learn.microsoft.com/sql/linux/sql-server-linux-encrypted-connections)

### 建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `*.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkdir -p certs
mkcert -cert-file certs/cert.pem -key-file certs/key.pem '*.dev.local'
```

> 如果是使用自簽憑證的話，用戶端可以加上 `TrustServerCertificate=true` 配置以信任該憑證

```sh
# 啟用 TLS 加密連線
COMPOSE_FILE=docker-compose.yml:docker-compose.tls.yml docker compose up -d

# 確認已正確啟用
docker compose exec mssql bash -c '/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $MSSQL_SA_PASSWORD -N -C -Q "SELECT encrypt_option FROM sys.dm_exec_connections WHERE session_id = @@SPID"'
```

## 重設資料庫 sa 帳號密碼

> 以下指令執行前請先關閉資料庫服務

```sh
# 進入容器的 Bash Shell
docker compose run --entrypoint=bash mssql

# 透過環境變數設定新密碼
export MSSQL_SA_PASSWORD="P@ssw0rd"

# 執行密碼重設
/opt/mssql/bin/mssql-conf set-sa-password
```

## 管理資料庫

以下示範使用 `mssql` 容器本身的工具來管理資料庫

> 執行前請先啟動資料庫服務

```sh
# 進入容器的 Bash Shell
docker compose exec mssql bash

export DBNAME=test

# 查詢指定資料庫的角色及成員
/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "Use [$DBNAME]; SELECT r.name role_principal_name, m.name AS member_principal_name FROM sys.database_role_members rm JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id WHERE r.type = 'R';"

# 備份資料庫
/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "BACKUP DATABASE [$DBNAME] TO DISK = N'/var/backups/$DBNAME.bak' WITH NOFORMAT, NOINIT, NAME = 'sample-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

# 還原資料庫
/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "RESTORE DATABASE [$DBNAME] FROM DISK = N'/var/backups/$DBNAME.bak' WITH FILE = 1, NOUNLOAD, REPLACE, NORECOVERY, STATS = 5"
```
