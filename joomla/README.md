# Joomla 開發環境 for Docker

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
docker-compose up -d db

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

- 80: HTTP

> 請參考 `docker-compose.yml` 的內容做調整

## 建立本機開發用的 SSL 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 SSL 憑證

以網域名稱 `dev.joomla.test` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 SSL 憑證
mkcert -cert-file etc/nginx/cert.pem -key-file etc/nginx/cert.key dev.joomla.test
```

## 啟用 HTTPS 連線

配置完成 SSL 憑證後，可修改 `etc/nginx/conf.d/default.conf` 以啟用 HTTPS 連線

> 可參考 [https://cipherli.st/](https://cipherli.st/) 以強化 HTTPS 安全性

```nginx
server {
    server_name  dev.joomla.test;
    listen       80 default_server;
    listen       443 ssl http2;
    ssl_certificate      cert.pem;
    ssl_certificate_key  cert.key;
}
```

> 請記得調整 `docker-compose.yml` 以啟用 HTTPS 連線

## 還原網站的方法

1. 先利用 Akeeba Backup 元件或 Akeeba Solo 完整備份 Joomla 網站 並將壓縮檔放在 web 目錄下
2. 下載 [Akeeba Kickstart](https://www.akeebabackup.com/download.html) 並解壓縮至 web 目錄下
3. 利用瀏覽器開啟解壓縮的 [Kickstart 主頁面](http://127.0.0.1/kickstart.php)
4. 選取要還原的備份檔並選以解壓縮檔模式為 `Directly` 後開始進行解壓縮
5. 解壓縮完成後將開啟 [Kickstart 安裝頁面](http://127.0.0.1/installation/) 進行網站還原
6. 在資料庫還原階段, 資料庫主機名稱請設定為 db 即可使用 MariaDB 資料庫容器

    建議保留表格名稱前綴,否則會因為 Joomla 內部預設資料表前綴(`jos_`) 而找不到資料表

7. 網站還原完成後，回到 Kickstart 主頁面執行 Clean Up

    如果無法執行 Clean Up, 可以手動清理如下檔案及目錄
    - `web/kicketstart.php`
    - `web/en-GB.kickstart.ini`
    - `web/installation/`
    - `web/*.jpa`

## 開發環境調整

請修改 `web/configuration.php` 的 `$live_site` 值為開發時期使用的網址

```php
public $live_site = 'https://dev.joomla.test';
```

## 初始化資料庫

將資料庫匯出檔 `*.sql` 或 `*.sql.gz` 放在相對於目前專案的 `etc/mysql/initdb.d` 目錄下即可

> 只有在初始化資料庫(第一次建立)時會自動匯入

## 重設資料庫密碼

> 以下指令執行前請先啟動資料庫服務

```sh
# 直接重設 root 帳號密碼
docker-compose exec db mysqladmin -u root password 'new-password'

# 或是透過以下互動程序來設定所有安全性選項
docker-compose exec db mysql_secure_installation
```

## 管理資料庫

- 可調整 `docker-compose.yml` 啟用 `adminer` 容器來管理資料庫
- 可調整 `docker-compose.yml` 開放 `db` 容器的本機連接埠，利用本機工具來管理資料庫

以下示範使用 `db` 容器本身的工具來管理資料庫

> 執行前請先啟動資料庫服務

可以透過設定[認證資訊](https://dev.mysql.com/doc/refman/8.0/en/password-security-user.html)於 `etc/mysql/conf.d/my.cnf` 簡化認證流程

```sh
# 完整備份容器內的資料庫
docker-compose exec db mysqldump --add-drop-database --insert-ignore --databases sample | gzip > backup.sql.gz

# 匯入本機的 SQL 備份檔至容器內的資料庫內
cat backup.sql | docker exec -i $(docker-compose ps -q db) mysql

# 匯入本機壓縮的 SQL 備份檔至容器內的資料庫內
gzip -dc backup.sql.gz | docker exec -i $(docker-compose ps -q db) mysql

# 進入容器的 bash shell
docker-compose exec db bash
```

## PHP XDebug 遠端偵錯

請調整 `docker-compose.yml` 啟用 `XDEBUG_CONFIG` 的環境變數以進行遠端偵錯

可參考 [PHP Debug for VSCode](https://code.visualstudio.com/docs/languages/php#_debugging) 或 [PHPStorm](https://www.jetbrains.com/help/phpstorm/zero-configuration-debugging.html) 等 IDE 的配置說明

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
