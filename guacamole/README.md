# [Guacamole 遠端桌面閘道](https://guacamole.apache.org/doc/gug/guacamole-docker.html)

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
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 8080: HTTP

## [初始化資料庫](https://guacamole.apache.org/doc/gug/guacamole-docker.html#guacamole-docker-mysql)

> 執行前請先啟動資料庫服務

```sh
# 產生 MySQL 初始化腳本
docker compose run --rm guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql

# 在 MySQL 容器執行初始化腳本
cat initdb.sql | docker exec -i $(docker compose ps -q mysql) bash -c 'mysql -uguacamole -p$(cat /run/secrets/mysql-user.pwd) guacamole'
```

## 開始使用

請以瀏覽器開啟 http://localhost:8080/guacamole , 以預設帳號密碼 guacadmin/guacadmin 登入後開始使用

> 如有開放外部存取請記得變更帳密
