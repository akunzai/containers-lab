# PHP 開發環境 for Docker

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)

## 運行開發環境

> `docker-compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行
>
> 可透過建立 `docker-compose.override.yml` 來擴展 `docker-compose.yml` 組態
>
> 還可以利用 [COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file) 環境變數指定多個組態來擴展服務配置

```sh
# 啟動並執行完整應用(若配置有異動會自動重建容器)
docker-compose up

# 在背景啟動並執行完整應用
docker-compose up -d

# 在背景啟動應用時指定服務的執行個數數量
docker-compose up -d --scale php=2

# 在背景啟動並執行指定服務
docker-compose up -d php

# 顯示記錄
docker-compose logs

# 持續顯示記錄
docker-compose logs -f

# 關閉應用
docker-compose down

# 顯示所有啟動中的容器
docker ps

# 如果需要在本機偵錯 PHP 應用程式的話
COMPOSE_FILE=docker-compose.yml:docker-compose.xdebug.yml docker-compose up -d

# 如果需要擴展以使用自訂的 PHP-FPM 執行環境的話
COMPOSE_FILE=docker-compose.yml:docker-compose.fpm.yml docker-compose up -d
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 80: HTTP
- 8080: Traefik 負載平衡器管理後台

## [啟用 HTTPS 連線](https://doc.traefik.io/traefik/https/tls/)

### [使用 Let's Encrypt 自動產生憑證](https://doc.traefik.io/traefik/https/acme/)

### 建立本機開發用的 SSL 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 SSL 憑證

以網域名稱 `*.example.test` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 SSL 憑證
mkdir -p traefik/conf/ssl
mkcert -cert-file traefik/conf/ssl/cert.pem -key-file traefik/conf/ssl/key.pem '*.example.test'
```

配置完成 SSL 憑證後，可修改 `docker-compose.yml` 並加入 TLS 檔案配置以啟用 HTTPS 連線

```sh
mkdir -p traefik/conf/dynamic
cat <<EOF > traefik/conf/dynamic/tls.yml
tls:
  stores:
    default:
      defaultCertificate:
        certFile: /etc/traefik/ssl/cert.pem
        keyFile: /etc/traefik/ssl/key.pem
EOF
```

## 利用容器執行指令

```sh
# 預設執行身份為 root
$ docker-compose run --rm php whoami
root

# 指定執行身份為 www-data
$ docker-compose run --rm --user www-data php whoami
www-data

# 執行 Bash Shell
$ docker-compose run --rm php bash
```

## [自訂和調整](https://docs.microsoft.com/azure/app-service/containers/configure-language-php)

### [自訂啟動腳本](https://github.com/Azure-App-Service/ImageBuilder/blob/master/GenerateDockerFiles/php/apache/init_container.sh)

在本機開發時可以透過 [command](https://docs.docker.com/compose/compose-file/#command) 屬性設定啟動命令

而在 Azure App Service 則可以在組態頁面的一般設定中設定啟動命令

### [自訂 PHP 組態設定](https://docs.microsoft.com/azure/app-service/containers/configure-language-php#customize-phpini-settings)

請擴展 PHP 容器配置並啟用 `PHP_INI_SCAN_DIR` 環境變數配置

之後便可以在 `home/site/ini` 目錄下加入自訂的 `.ini` 檔案以自訂 [php.ini](https://www.php.net/manual/ini.list.php) 組態

> 也可在網站目錄下的 [.htaccess](https://httpd.apache.org/docs/2.4/howto/htaccess.html) 使用 `php_value` 語法自訂組態設定, 但僅限非 `PHP_INI_SYSTEM` 類型的設定

組態範例如下

```ini:php.ini
expose_php=Off
memory_limit=512M
upload_max_filesize=256M
post_max_size=256M
max_execution_time=600
output_buffering=4096
error_reporting=E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED
```

### [啟用 PHP 擴充功能](https://docs.microsoft.com/azure/app-service/containers/configure-language-php#enable-php-extensions)

必須先參考上面的說明啟用自訂 PHP 組態設定後才能啟用額外的 PHP 擴充功能

> 以下指令請在 PHP 容器內執行

```sh
[[ -e /home/site/lib ]] || mkdir /home/site/lib
[[ -e /home/site/ini ]] || mkdir /home/site/ini

# 透過 docker-php-ext-install 安裝擴充功能
apt-get update && apt-get install -y libxml2-dev
docker-php-ext-install soap
find /usr/local/lib/php/extensions -name soap.so -exec cp {} /home/site/lib/ \;
echo "extension=/home/site/lib/soap.so" > /home/site/ini/soap.ini

# 透過 pecl 安裝擴充功能
pecl install redis
find /usr/local/lib/php/extensions -name redis.so -exec cp {} /home/site/lib/ \;
echo "extension=/home/site/lib/redis.so" > /home/site/ini/redis.ini
```

### 安裝工具程式

可將工具程式安裝在 `/home/site/wwwroot/` (永續儲存區), 避免額外客製容器映像檔的需要

> 以下指令請在 PHP 容器內執行

以安裝 [Composer](https://getcomposer.org/) 工具為例

```sh
curl -sS https://getcomposer.org/installer | php -- --install-dir=/home/site/wwwroot/ --filename=composer
```

建議可以建立網站目錄下的 [.htaccess](https://httpd.apache.org/docs/2.4/howto/htaccess.html) 以限制透過網路存取工具程式

```apache:.htaccess
<FilesMatch "^composer$">
    Require all denied
</FilesMatch>
```

## 偵錯應用程式

如果需要在 Azure App Service 上偵錯, 請新增[應用系統設定](https://docs.microsoft.com/azure/app-service/configure-common#configure-app-settings) `PHP_ZENDEXTENSIONS` 加入 `xdebug` 設定值

可參考 [PHP Debug for VSCode](https://code.visualstudio.com/docs/languages/php#_debugging) 或 [PHPStorm](https://www.jetbrains.com/help/phpstorm/zero-configuration-debugging.html) 等 IDE 的配置說明

> 需要在 HTTP 請求中加入 `XDEBUG_SESSION_START` URL 參數或 `XDEBUG_SESSION` Cookie 以啟用遠端偵錯
> 建議可透過[瀏覽器外掛](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc)來切換

## 備份或還原網站

### 透過指令

```sh
# 備份資料庫
mysqldump --add-drop-database --insert-ignore --databases sample | gzip > backup.sql.gz
# 還原資料庫
gzip -dc backup.sql.gz | mysql

# 備份檔案 (假設當下目錄即為網站根目錄)
tar -zcvf /tmp/backup.file.tgz --exclude='./node_modules/*' ./
# 還原檔案
tar -zxvf /tmp/backup.file.tgz

# 或是利用 rsync 差異同步暨有網站檔案 (以下為測試模式，實際執行請拿掉 --dry-run 選項)
rsync --dry-run -vrlP --delete \
    --exclude='/node_modules/' \
    --exclude='/configuration.php' \
    HOST:/var/www/html/ ./
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

### 啟用 HTTPS 後, 瀏覽器連線時出現重導迴圈的狀況

可以試著在網站根目錄下的 [.htaccess](https://httpd.apache.org/docs/2.4/howto/htaccess.html)加入以下配置

```apache:.htaccess
SetEnvIf X-Forwarded-Proto https HTTPS=on
```
