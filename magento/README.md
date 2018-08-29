# Magento 開發環境 for Docker

## 環境需求

- [Docker Engine](https://docs.docker.com/engine/installation/)

## 運行開發環境

> `docker-compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行

```sh
# 啟動並執行完整應用
$ docker-compose up
# 在背景啟動並執行完整應用
$ docker-compose up -d
# 顯示記錄
$ docker-compose logs
# 持續顯示記錄
$ docker-compose logs -f
# 關閉應用
$ docker-compose down
# 顯示所有啟動中的容器
$ docker ps
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 8080: HTTP
- 8443: HTTPS

請參考 `docker-compose.yml` 的內容做調整

## SSL 憑證

內含以下網域的 SSL 憑證

- `*.localhost`: `etc/nginx/ssl/_localhost/cert.*`
- `*.test`: `etc/nginx/ssl/_test/cert.*`
- `localhost`: `etc/nginx/ssl/localhost/cert.*`

預設是使用 `localhost` 的 SSL 憑證
如需變更請調整 `etc/nginx/conf.d/default.conf` 中的 `server_name` 及以 `ssl_certificate`,`ssl_certificate_key` 等配置

## 初始化資料庫

將資料庫匯出檔 `*.sql` 或 `*.sql.gz` 放在相對於目前專案的 `etc/mysql/initdb.d` 目錄下即可

> 只有在初始化資料庫(第一次建立)時會自動匯入

## 重設資料庫密碼

```sh
# 直接重設 root 帳號密碼
docker-compose exec db mysqladmin -u root password 'new-password'
# 或是透過以下互動程序來設定所有安全性選項
docker-compose exec db mysql_secure_installation
```

## 管理資料庫

- 可調整 `docker-compose.yml` 啟用 `phpmyadmin` 容器來管理資料庫
- 可調整 `docker-compose.yml` 開放 `db` 容器的本機連接埠，利用本機工具來管理資料庫
- 可利用 `db` 容器本身的工具來管理資料庫

```sh
# 建立名為 magento 的資料庫
docker-compose db mysqladmin -u root create magento
# 匯入本機的 magento.sql 至容器內名為 magento 的資料庫內
docker-compose db mysql -u root magento < magento.sql
# 匯入 gzip 壓縮的備份檔
gzip -dc magento.sql.gz | docker-compose db mysql -u root magento
```

## PHP XDebug 遠端偵錯

請調整 `docker-compose.yml` 啟用 `XDEBUG_CONFIG` 的環境變數以進行遠端偵錯

可參考 [PHP Debug for VSCode](https://code.visualstudio.com/docs/languages/php#_debugging) 或 [PHPStorm](https://confluence.jetbrains.com/display/PhpStorm/Zero-configuration+Web+Application+Debugging+with+Xdebug+and+PhpStorm) 等 IDE 的配置說明

> 需要在 HTTP 請求中加入 `XDEBUG_SESSION_START` URL 參數或 `XDEBUG_SESSION` Cookie 以啟用遠端偵錯
> 建議可透過[瀏覽器外掛](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc)來切換

## 利用 cli 容器執行指令

```sh
# 預設執行身份為 www-data
$ docker-compose run --rm cli whoami
www-data
# 改用 root 身份執行指令
$ docker-compose run --rm --user root cli whoami
root
# 顯示 composer 版本
$ docker-compose run --rm cli composer -V
Composer version 1.5.2 2017-09-11 16:59:25
# 執行 bash shell
$ docker-compose run --rm cli bash
```

## 安裝 Magento

> 請先啟動並執行完整應用

```sh
# 以互動模式安裝 Magento
docker-compose run --rm cli n98-magerun install
```

## Magento 組態設定

請將 Magento 組態檔還原至 `web` 目錄下的 `app/etc/local.xml`

> 如果要連線本測試環境的 MariaDB 環境，請記得將資料庫主機設定為 `db`

## 開發環境調整

> cli 容器預設會以 `www-data` 身份執行指令

```sh
# 關閉快取
docker-compose run --rm cli n98-magerun cache:disable
# 設定未加密的基礎網址
docker-compose run --rm cli n98-magerun config:set 'web/unsecure/base_url' 'http://dev.magento.test:8080/'
# 設定加密的基礎網址
docker-compose run --rm cli n98-magerun config:set 'web/secure/base_url' 'https://dev.magento.test:8443/'
# 切換允許開發人員樣版的 "符號連結"
docker-compose run --rm cli n98-magerun config:set 'dev/template/allow_symlink' '1'
# 以 root 身份執行指令
docker-compose run --rm --user root cli bash
```

## 模組管理

> 以下指令請進入 cli 容器內執行

```sh
# 初始化 mage 配置
/var/www/html/mage mage-setup /var/www/html
/var/www/html/mage config-set preferred_state stable
# 利用 mage 安裝模組
/var/www/html/mage install http://connect20.magentocommerce.com/community ASchroder_SMTPPro
# 列出己安裝的 mage 模組
/var/www/html/mage list-installed

# 初始化 modman 配置
modman init
# 確保 ssh id 的權限
chmod 700 ~/.ssh/id_*
# 利用 modman 安裝模組
modman clone git@git.gss.com.tw:gsscloud/magento-translation-zh_TW.git
modman clone git@git.gss.com.tw:gsscloud/magento-provisioning.git
modman clone git@git.gss.com.tw:gsscloud/magento-priceRounding.git
modman clone git@git.gss.com.tw:gsscloud/magento-ezCheckout.git
modman clone git@git.gss.com.tw:gsscloud/magento-extapi2.git
modman clone git@git.gss.com.tw:gsscloud/magento-enhancedEcommerce.git
modman clone git@git.gss.com.tw:gsscloud/magento-customize-gsscloud.git
modman clone git@git.gss.com.tw:gsscloud/magento-customerNotification.git
modman clone git@git.gss.com.tw:gsscloud/magento-customerApi.git
modman clone git@git.gss.com.tw:gsscloud/magento-affiliateplus-platinum.git
modman clone git@git.gss.com.tw:gsscloud/magento-affiliateApi.git
modman clone git@git.gss.com.tw:gsscloud/magento-affiliateplus-customize.git
# 安裝此模組前需要先安裝並啟用 Aitoc Checkout Fields Manager (需升級以支援 Magento 1.9 最新版)
modman clone git@git.gss.com.tw:gsscloud/magento-aitcheckoutfieldsApi2.git
modman clone git@git.gss.com.tw:gsscloud/Spgateway_MPG_Magento.git
modman clone https://github.com/yireo/MageBridgeCore.git
modman clone https://github.com/yireo/Yireo_CheckoutTester
modman clone https://github.com/jacquesbh/jbh_cartmerge.git
# 列出己安裝的 modman 模組
modman list
```