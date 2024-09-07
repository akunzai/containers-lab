# PHP 開發環境

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟網站
npx open-cli http://localhost:8080
```

## [啟用 TLS 加密連線](https://httpd.apache.org/docs/2.4/ssl/ssl_faq.html)

建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `www.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkcert -cert-file ./cert.pem -key-file ./key.pem '*.dev.local' localhost

# 產生 Podman secrets
podman secret exists dev.local.key || podman secret create dev.local.key ./key.pem
podman secret exists dev.local.crt || podman secret create dev.local.crt ./cert.pem

# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose up -d

# 確認已正確啟用
curl -v 'https://www.dev.local:8443'
```

## 利用容器執行指令

```sh
# 預設執行身分為 www-data
$ podman-compose run --rm php whoami
www-data

# 指定執行身分為 www-data
$ podman-compose run --rm --user root php whoami
root

# 進入 Shell 互動環境
$ podman-compose run --rm php bash
```

### 自訂 PHP 組態設定

請擴展 PHP 容器配置並啟用 [PHP_INI_SCAN_DIR](https://www.php.net/manual/en/configuration.file.php#configuration.file.scan) 環境變數配置

例如: `PHP_INI_SCAN_DIR=/usr/local/etc/php/conf.d:/home/site/ini`

之後便可以在 `/home/site/ini` 目錄下加入自訂的 `.ini` 檔案以自訂 [php.ini](https://www.php.net/manual/ini.list.php) 組態

> 也可在網站目錄下的 [.htaccess](https://httpd.apache.org/docs/2.4/howto/htaccess.html) 使用 `php_value` 語法自訂組態設定, 但僅限非 `PHP_INI_SYSTEM` 類型的設定

組態範例如下

```ini:php.ini
expose_php=Off
memory_limit=512M
upload_max_filesize=256M
post_max_size=256M
max_execution_time=300
output_buffering=4096
; https://www.php.net/manual/en/errorfunc.configuration.php
error_reporting=E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED
display_errors=Off
display_startup_errors=Off
log_errors=On
error_log=/dev/stderr
log_errors_max_len=1024
ignore_repeated_errors=On
ignore_repeated_source=Off
html_errors=Off
; https://www.php.net/manual/en/opcache.installation.php
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.enable_cli=1
```

### [啟用 PHP 擴充功能](https://learn.microsoft.com/azure/app-service/configure-language-php?pivots=platform-linux#enable-php-extensions)

必須先參考上面的說明啟用自訂 PHP 組態設定後才能啟用額外的 PHP 擴充功能

> 以下指令請在 PHP 容器內執行

```sh
[ -e /home/site/lib ] || mkdir -p /home/site/lib
[ -e /home/site/ini ] || mkdir -p /home/site/ini

# 透過 docker-php-ext-install 安裝 PHP 內建的擴充功能
# https://www.php.net/manual/en/extensions.alphabetical.php
apt-get update && apt-get install -y libxml2-dev
docker-php-ext-install soap
find /usr/local/lib/php/extensions -name soap.so -exec cp {} /home/site/lib/ \;
tee -a /home/site/ini/php.ini << EOF
extension=/home/site/lib/soap.so
EOF

# 透過 pickle 安裝第三方的擴充功能
pickle install --no-interaction xdebug
find /usr/local/lib/php/extensions -name xdebug.so -exec cp {} /home/site/lib/ \;
tee -a /home/site/ini/php.ini << EOF
zend_extension=/home/site/lib/xdebug.so
EOF
```

### 安裝工具程式

可將工具程式安裝在 `/home/site/bin/` 目錄下

> 以下指令請在 PHP 容器內執行

以安裝 [modman](https://github.com/colinmollenhour/modman) 工具為例

```sh
[ -e /home/site/bin ] || mkdir -p /home/site/bin
curl -fSL -o /home/site/bin/modman https://raw.githubusercontent.com/colinmollenhour/modman/master/modman
chmod +x home/site/bin/modman
```

記得要將 `/home/site/bin/` 加入至 `PATH` 環境變數

- PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/site/bin

## 備份或還原網站

### 透過指令

```sh
# 備份資料庫
mysqldump --single-transaction --add-drop-database --insert-ignore --databases sample | gzip > /var/backups/site.sql.gz
# 還原資料庫
gzip -dc /var/backups/site.sql.gz | mysql

# 備份檔案 (假設當下目錄即為網站根目錄)
tar -zcvf /var/backups/site.file.tgz --exclude='./node_modules/' .
# 還原檔案
tar -zxvf /var/backups/site.file.tgz

# 或是利用 rsync 差異同步暨有網站檔案 (以下為測試模式，實際執行請拿掉 --dry-run 選項)
rsync --dry-run -lcrvhP --delete \
    --exclude='./node_modules/' \
    --exclude='./configuration.php' \
    $REMOTE_HOST:/var/www/html/ .
```

### 透過 [Akeeba Backup](https://www.akeebabackup.com/)

1. 先利用網站的 Akeeba Backup 擴充套件進行完整備份 並將壓縮檔放在 `home/site/wwwroot` 目錄下
2. 下載 [Akeeba Kickstart](https://www.akeebabackup.com/download.html) 並解壓縮至 `home/site/wwwroot` 目錄下
3. 利用瀏覽器開啟解壓縮的 [Kickstart 主頁面](http://127.0.0.1/kickstart.php)
4. 選取要還原的備份檔並選以解壓縮檔模式為 `Directly` 後開始進行解壓縮
5. 解壓縮完成後將開啟 [Kickstart 安裝頁面](http://127.0.0.1/installation/) 進行網站還原
6. 還原資料庫 (建議保留表格名稱前綴，當使用本機的資料庫服務容器時，資料庫主機名稱請設定為 `mysql`)
7. 網站還原完成後，回到 Kickstart 主頁面執行 `Clean Up`

如果無法執行 `Clean Up`, 請手動清理

```sh
cd /home/site/wwwroot
rm kicketstart.php en-GB.kickstart.ini
rm -rf installation
rm -i *.jpa
```

## 疑難排解

### [偵錯應用程式](https://xdebug.org/docs/step_debug)

> 如果需要在 Azure App Service 上偵錯, 請新增[應用系統設定](https://learn.microsoft.com/azure/app-service/configure-common#configure-app-settings) `PHP_ZENDEXTENSIONS` 加入 `xdebug` 設定值

安裝 XDebug 擴充功能後，請加入以下的環境變數以利啟用偵錯

- `XDEBUG_MODE: debug`

> 如果 XDebug 擴充功能是安裝在宿主的話

- `XDEBUG_CONFIG: client_host=host.docker.internal`

> 如果 XDebug 擴充功能是安裝在容器的話

- `XDEBUG_CONFIG: client_host=localhost`

可參考 [PHP Debug for Visual Studio Code](https://code.visualstudio.com/docs/languages/php#_debugging) 或 [PhpStorm](https://www.jetbrains.com/help/phpstorm/zero-configuration-debugging.html) 等 IDE 的配置說明

> 需要在 HTTP 請求中加入 [XDEBUG_TRIGGER](https://xdebug.org/docs/step_debug#start_with_request) 的 Cookie 或 URL 參數以啟用遠端偵錯
> 建議可透過[瀏覽器外掛](https://xdebug.org/docs/step_debug#browser-extensions)來切換

### 啟用 HTTPS 後, 瀏覽器連線時出現重導迴圈的狀況

可以試著在網站根目錄下的 [.htaccess](https://httpd.apache.org/docs/2.4/howto/htaccess.html)加入以下配置

```apache:.htaccess
SetEnvIf X-Forwarded-Proto https HTTPS=on
```
