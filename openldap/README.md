# OpenLDAP 開發環境 for Docker

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)

## 運行開發環境

> `docker-compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行

```sh
# 啟動並執行完整應用
docker-compose up

# 在背景啟動並執行完整應用
docker-compose up -d

# 在背景啟動並執行指定服務
docker-compose up -d slapd

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

- 389: LDAP

> 請參考 `docker-compose.yml` 的內容做調整

## 管理資料庫

- 可利用本機工具直接存取 `slapd` 容器的本機連接埠來管理資料庫
- 可利用 `slapd` 或 `cli` 容器本身的工具來管理資料庫

```sh
# 依據目錄後綴匯出為 LDIF (此例為 LDAP config files)
docker-compose run --rm cli slapcat -b cn=config > config.ldif

# 依據資料庫索引匯出為 LDIF (此例為 LDAP database files)
docker-compose run --rm cli slapcat -n 1 > data.ldif

# 暫時關閉 slapd 容器以利還原資料庫
docker-compose down

# 刪除 LDAP config files 以利還原
docker-compose run --rm cli sh -c 'rm -rf /etc/ldap/slapd.d/*'
# 還原 LDAP config files
cat config.ldif | docker-compose run --rm cli slapadd -F /etc/ldap/slapd.d -n 0

# 刪除 LDAP database files
docker-compose run --rm cli sh -c 'rm -rf /var/lib/ldap/*'
# 還原 LDAP database files
cat data.ldif | docker-compose run --rm cli slapadd -F /etc/ldap/slapd.d -n 1
```
