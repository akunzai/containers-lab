# OpenLDAP 開發環境 for Docker

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## 運行開發環境

> `docker compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行

可透過建立 `docker-compose.override.yml` 來擴展 `docker-compose.yml` 組態

```sh
# 啟動並執行完整應用
docker compose up

# 在背景啟動並執行完整應用
docker compose up -d

# 在背景啟動並執行指定服務
docker compose up -d ldap

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

- 389: LDAP

## 管理資料庫

以下示範使用 `ldap-cli` 容器來管理資料庫

> 還原資料庫前請記得暫時關閉啟動中的 `ldap` 容器以避免資料存取衝突

```sh
# 依據目錄後綴匯出為 LDIF (此例為 LDAP config files)
docker compose run --rm ldap-cli slapcat -b cn=config > config.ldif

# 依據資料庫索引匯出為 LDIF (此例為 LDAP database files)
docker compose run --rm ldap-cli slapcat -n 1 > data.ldif

# 刪除 LDAP config files 以利還原
docker compose run --rm ldap-cli sh -c 'rm -rf /etc/ldap/slapd.d/*'
# 還原 LDAP config files
cat config.ldif | docker compose -T run --rm ldap-cli slapadd -F /etc/ldap/slapd.d -n 0

# 刪除 LDAP database files
docker compose run --rm ldap-cli sh -c 'rm -rf /var/lib/ldap/*'
# 還原 LDAP database files
cat data.ldif | docker compose run -T --rm ldap-cli slapadd -F /etc/ldap/slapd.d -n 1
```
