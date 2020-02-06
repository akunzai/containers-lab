# MySQL 開發環境 for Docker

## 環境需求

- [Docker Engine](https://docs.docker.com/engine/installation/)

## 運行開發環境

> `docker-compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行

```sh
# 啟動並執行完整應用
docker-compose up

# 在背景啟動並執行完整應用
docker-compose up -d

# 在背景啟動並執行指定服務
docker-compose up -d db

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

- 3306: MySQL

> 請參考 `docker-compose.yml` 的內容做調整

## 初始化資料庫

將資料庫匯出檔 `*.sql` 或 `*.sql.gz` 放在相對於目前專案的 `etc/mysql/initdb.d` 目錄下即可

> 只有在初始化資料庫(第一次建立)時會自動匯入

## 重設資料庫密碼

> 以下指令執行前請先啟動資料庫服務

```sh
# 直接重設 root 帳號密碼
docker-compose exec db mysqladmin -u root password 'new-password'

# 或是透過以下互動程序來設定所有安全性選項
docker-compose exec db mysql_secure_installation
```

## 管理資料庫

> 以下指令執行前請先啟動資料庫服務

- 可調整 `docker-compose.yml` 啟用 `adminer` 容器來管理資料庫
- 可調整 `docker-compose.yml` 開放 `db` 容器的本機連接埠，利用本機工具來管理資料庫
- 可利用 `db` 容器本身的工具來管理資料庫
- 請自行替換下列指令中的 `$MYSQL_ROOT_PASSWORD` 為實際的密碼

```sh
# 刪除暨有資料庫
docker-compose exec db mysqladmin -u root -p drop test

# 創建新的資料庫
docker-compose exec db mysqladmin -u root -p create test

# 匯入本機的 SQL 備份檔至容器內的資料庫內
cat test.sql | docker exec -i $(docker-compose ps -q db) mysql -u root -p$MYSQL_ROOT_PASSWORD test

# 匯入本機壓縮的 SQL 備份檔至容器內的資料庫內
gzip -dc test.sql.gz | docker exec -i $(docker-compose ps -q db) mysql -u root -p$MYSQL_ROOT_PASSWORD test
```
