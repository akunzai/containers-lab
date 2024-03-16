# OpenLDAP 目錄伺服器

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## 使用方式

> `docker compose` 指令必須要在 `compose.yml` 所在的目錄下執行

可透過建立 `compose.override.yml` 來擴展 `compose.yml` 組態

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
- 8080: LDAP 網頁管理介面

## [預設存取憑證](https://github.com/osixia/docker-openldap#defaultyaml)

- BaseDN: dc=example,dc=org
- BindDN: cn=admin,dc=example,dc=org
- Password: admin

---

- BaseDN: cn=config
- BindDN: cn=admin,cn=config
- Password: config

## 管理資料庫

以下示範使用 `ldap-cli` 容器來管理資料庫

> 還原資料庫前請記得暫時關閉啟動中的 `ldap` 容器或掛載不同的檔案系統以避免資料存取衝突

```sh
# 進入容器的 Bash Shell
docker compose run --rm ldap-cli bash

# 依據目錄後綴匯出為 LDIF (此例為 LDAP config files)
slapcat -b cn=config > conf.ldif

# 依據資料庫索引匯出為 LDIF (此例為 LDAP database files)
slapcat -n 1 > data.ldif

# 刪除 LDAP config files 以利還原
rm -rf /etc/ldap/slapd.d/*

# 還原 LDAP config files
cat conf.ldif | slapadd -vF /etc/ldap/slapd.d -n 0

# 刪除 LDAP database files
rm -rf /var/lib/ldap/*

# 還原 LDAP database files
cat data.ldif | slapadd -vF /etc/ldap/slapd.d -n 1
```

## 疑難排解

### [支援 ARGON2 密碼演算法](https://github.com/openldap/openldap/tree/master/servers/slapd/pwmods)

```sh
# 啟用 pw-argon2 模組
ldapadd -Y EXTERNAL -H ldapi:/// <<'EOF'
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: pw-argon2
EOF

# 變更預設的密碼雜湊演算法
ldapadd -Y EXTERNAL -H ldapi:/// <<'EOF'
dn: olcDatabase={-1}frontend,cn=config
changetype: modify
add: olcPasswordHash
olcPasswordHash: {ARGON2}
EOF

# 測試產生 ARGON2 雜湊密碼
slappasswd -o module-load=pw-argon2.la -h {ARGON2} -s secret

# 測試新增 ARGON2 雜湊密碼給指定使用者
ldapadd -Y EXTERNAL -H ldapi:/// <<'EOF'
dn: uid=78783f05-ff4d-4334-91f2-079807fe3491,ou=users,dc=example,dc=org
changetype: modify
add: userPassword
userPassword: {ARGON2}$argon2i$v=19$m=4096,t=3,p=1$bf/rsEZQSwMbBxf9UrjObg$vYKrAJrwozyjwXM3sMuzUMf8Mmz0CwhS6utvyaj4JC8
EOF

# 測試使用 ARGON2 雜湊密碼認證指定使用者
ldapsearch -x -D 'uid=78783f05-ff4d-4334-91f2-079807fe3491,ou=users,dc=example,dc=org' -W
```
