# [SQL Server](https://learn.microsoft.com/sql/linux/sql-server-linux-overview) 資料庫

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## Getting Started

```sh
# 產生 Podman secrets
podman secret exists mssql_root.pwd || openssl rand -base64 16 | podman secret create mssql_root.pwd -
podman secret exists mssql_user.pwd || openssl rand -base64 16 | podman secret create mssql_user.pwd -

# 在背景啟動並執行完整應用
podman-compose up -d

# 如果需要使用網頁介面管理資料庫的話
COMPOSE_FILE=compose.yml:compose.dbgate.yml podman-compose up -d
```

## [啟用 TLS 加密連線](https://learn.microsoft.com/sql/linux/sql-server-linux-encrypted-connections)

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

> 如果是使用自簽憑證的話，用戶端可以加上 `TrustServerCertificate=true` 配置以信任該憑證

```sh
# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose up -d

# 確認已正確啟用
podman-compose exec mssql bash -c '/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P $(cat /run/secrets/mssql_root.pwd) -N -C -Q "SELECT encrypt_option FROM sys.dm_exec_connections WHERE session_id = @@SPID"'
```

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
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "SELECT name AS db, SUSER_SNAME(owner_sid) AS owner FROM sys.databases;"

# 變更資料庫的擁有者
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "ALTER AUTHORIZATION ON DATABASE::[$DBNAME] TO [$USERNAME];"

# 查詢資料庫層級的角色及成員
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "Use [$DBNAME]; SELECT r.name role_principal_name, m.name AS member_principal_name FROM sys.database_role_members rm JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id WHERE r.type = 'R';"

# 增加資料庫層級的擁有者角色成員
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "Use [$DBNAME]; CREATE USER [$USERNAME] FROM LOGIN [$USERNAME]; EXEC sp_addrolemember 'db_owner', '$USERNAME'"

# 備份資料庫
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "BACKUP DATABASE [$DBNAME] TO DISK = N'/var/backups/$DBNAME.bak' WITH NOFORMAT, NOINIT, NAME = 'sample-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

# 還原資料庫
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P $MSSQL_SA_PASSWORD -Q "RESTORE DATABASE [$DBNAME] FROM DISK = N'/var/backups/$DBNAME.bak' WITH FILE = 1, NOUNLOAD, REPLACE, NORECOVERY, STATS = 5"
```

## 疑難排解

### Configuration file (/var/opt/mssql/mssql.conf) exists but could not be opened or parsed. File: LinuxFile.cpp:418 [Status: 0xC0000022 Access Denied errno = 0xD(13) Permission denied]

```sh
podman-compose run --rm --user root mssql rm /var/opt/mssql/mssql.conf
```
