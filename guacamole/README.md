# [Guacamole 遠端桌面閘道](https://guacamole.apache.org/doc/gug/guacamole-docker.html)

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## Getting Started

```sh
# 在背景啟動並執行完整應用
docker compose up -d

# 初始化資料庫
# https://guacamole.apache.org/doc/gug/guacamole-docker.html#guacamole-docker-mysql
# > 產生 MySQL 初始化腳本
docker compose run --rm guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql

# > 在 MySQL 容器執行初始化腳本
cat initdb.sql | docker exec -i $(docker compose ps -q mysql) bash -c 'mysql -uguacamole -p$(cat /run/secrets/mysql_user.pwd) guacamole'

# 開啟管理介面, 預設的帳號與密碼皆為 guacadmin
# > 如有開放外部存取請記得變更帳密
open http://localhost:8080/guacamole
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 8080: HTTP
