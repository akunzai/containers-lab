# OpenLDAP 目錄伺服器

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 如果需要使用網頁管理介面的話
COMPOSE_FILE=compose.yml:compose.admin.yml podman-compose up -d
```

## [預設存取憑證](https://github.com/osixia/docker-openldap#defaultyaml)

- BaseDN: dc=example,dc=org
- BindDN: cn=admin,dc=example,dc=org
- Password: admin

---

- BaseDN: cn=config
- BindDN: cn=admin,cn=config
- Password: config

## [啟用 TLS 加密連線](https://github.com/osixia/docker-openldap?tab=readme-ov-file#use-your-own-certificate)

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `ldap.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkcert -cert-file ./cert.pem -key-file ./key.pem '*.dev.local' localhost

# 產生 Podman secrets
podman secret create --replace dev.local.key ./key.pem
podman secret create --replace dev.local.crt ./cert.pem
podman secret create --replace dev.CA.crt "$(mkcert -CAROOT)/rootCA.pem"

# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose up -d

# 確認已正確啟用
curl -kvu 'cn=admin,dc=example,dc=org:admin' 'ldaps://ldap.dev.local/ou=users,dc=example,dc=org??sub'
```

## 管理資料庫

以下示範使用 `ldap-cli` 容器來管理資料庫

> 還原資料庫前請記得暫時關閉啟動中的 `ldap` 容器或掛載不同的檔案系統以避免資料存取衝突

```sh
# 進入容器的 Bash Shell
podman-compose run --rm ldap-cli bash

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
