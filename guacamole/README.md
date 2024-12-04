# [Guacamole 遠端桌面閘道](https://guacamole.apache.org/doc/gug/guacamole-docker.html)

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## Getting Started

```sh
# 產生 Podman secrets
openssl rand -base64 16 | podman secret create --replace mysql_root.pwd -
openssl rand -base64 16 | podman secret create --replace mysql_user.pwd -

# 在背景啟動並執行完整應用
podman-compose up -d

# 初始化資料庫
# https://guacamole.apache.org/doc/gug/guacamole-docker.html#guacamole-docker-mysql
# > 產生 MySQL 初始化腳本
podman-compose run --rm guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql

# > 在 MySQL 容器執行初始化腳本
cat initdb.sql | podman exec -i $(podman ps -qf 'name=guacamole_mysql') sh -c 'mysql -uguacamole -p$(cat /run/secrets/mysql_user.pwd) guacamole'

# > 清理初始化腳本
rm initdb.sql

# 開啟管理介面, 預設的帳號與密碼皆為 guacadmin
# > 如有開放外部存取請記得變更帳密
npx open-cli http://localhost:8080/guacamole
```
