# [SQL Server](https://learn.microsoft.com/sql/linux/sql-server-linux-overview) 資料庫

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 產生 Podman secrets
openssl rand -base64 16 | podman secret create --replace mssql_root.pwd -
openssl rand -base64 16 | podman secret create --replace mssql_user.pwd -

# 在背景啟動並執行完整應用
podman-compose up -d

# 以互動方式使用 sqlcmd
# https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-use-utility
podman-compose exec mssql bash -c '/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U SA -P $(cat /run/secrets/mssql_root.pwd)'

# 如果需要使用網頁介面管理資料庫的話
podman-compose -f compose.yml -f compose.dbgate.yml up -d
```

## 高可用 (HA) 範例 – Read-Scale Availability Group

提供以 Podman Compose 建立兩節點的 Read-Scale AG（無叢集管理，手動切換）的範例配置，並附可選的 HAProxy 前端：

```sh
cd mssql/ha
# 啟動兩個節點
podman-compose -f compose.ha.yml up -d mssql1 mssql2

# 初始化 AG（建立憑證/端點、建立並加入 AG、加入示範資料庫）
podman-compose -f compose.ha.yml up --no-deps ag-setup

# （可選）啟動 HAProxy，統一以 localhost:1433 連線
podman-compose -f compose.ha.yml up -d haproxy
```

詳細說明請參考 `mssql/ha/README.md`。

## 重設資料庫 sa 帳號密碼

> 以下指令執行前請先關閉資料庫服務

```sh
# 進入容器的 Bash Shell
podman-compose run --entrypoint=bash mssql

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
podman-compose exec mssql bash

export DBNAME=test
export USERNAME=test

# 查詢所有資料庫的擁有者
/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "SELECT name AS db, SUSER_SNAME(owner_sid) AS owner FROM sys.databases;"

# 變更資料庫的擁有者
/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "ALTER AUTHORIZATION ON DATABASE::[$DBNAME] TO [$USERNAME];"

# 查詢資料庫層級的角色及成員
/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "Use [$DBNAME]; SELECT r.name role_principal_name, m.name AS member_principal_name FROM sys.database_role_members rm JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id WHERE r.type = 'R';"

# 增加資料庫層級的擁有者角色成員
/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "Use [$DBNAME]; CREATE USER [$USERNAME] FROM LOGIN [$USERNAME]; EXEC sp_addrolemember 'db_owner', '$USERNAME'"

# 備份資料庫
/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "BACKUP DATABASE [$DBNAME] TO DISK = N'/var/backups/$DBNAME.bak' WITH NOFORMAT, NOINIT, NAME = 'sample-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

# 還原資料庫
/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "RESTORE DATABASE [$DBNAME] FROM DISK = N'/var/backups/$DBNAME.bak' WITH FILE = 1, NOUNLOAD, REPLACE, NORECOVERY, STATS = 5"
```

## 疑難排解

### Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : SSL Provider: [error:0A000086:SSL routines::certificate verify failed:self-signed certificate]

自 [Microsoft ODBC Driver 18 for SQL Server](https://techcommunity.microsoft.com/t5/sql-server-blog/odbc-driver-18-0-for-sql-server-released/ba-p/3169228) 開始，加密連線及憑證檢查是必要的，請在用戶端連線字串加上 `TrustServerCertificate=true` 配置以信任伺服器憑證

sqlcmd 可加上 `-C` 選項以信任伺服器憑證或 `-No` 選項指定加密連線是選擇性的，而不是強制性的

### Configuration file (/var/opt/mssql/mssql.conf) exists but could not be opened or parsed. File: LinuxFile.cpp:418 [Status: 0xC0000022 Access Denied errno = 0xD(13) Permission denied]

```sh
podman-compose run --rm --user root mssql rm /var/opt/mssql/mssql.conf
```
