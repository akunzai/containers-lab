# Joomla 開發環境 for Docker

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

## 還原網站的方法

1. 先利用 Akeeba Backup 元件或 Akeeba Solo 完整備份 Joomla 網站 並將壓縮檔放在 web 目錄下
2. 下載 [Akeeba Kickstart](https://www.akeebabackup.com/download.html) 並解壓縮至 web 目錄下
3. 利用瀏覽器開啟 http://localhost:8080/kickstart.php 開始利用 Akeeba Kickstart 進行網站還原
4. 在 Akeeba Kickstart 選取要還原的備份檔並選以解壓縮檔模式為 `Directly` 後開始進行解壓縮
5. 解壓縮完成後會開啟 http://localhost:8080/installation/index.php 進行網站還原動作
6. 在資料庫還原階段,資料庫主機名稱請設定為 db 即可使用 MariaDB 資料庫容器

> 建議保留表格名稱前綴,否則會因為 Joomla 內部預設資料表前綴(`jos_`) 而找不到資料表

## 開發環境調整

請修改 `web/configuration.php` 的 `$live_site` 值為開發時期使用的網址

```php
public $live_site = 'https://localhost:8443';
```

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

> 己知管線指令目前在 Docker for Windows 的 Shell 環境可能無法正確地運作

```sh
# 建立名為 joomla 的資料庫
docker-compose db mysqladmin -u root create joomla
# 匯入本機的 joomla.sql 至容器內名為 joomla 的資料庫內
docker-compose db mysql -u root joomla < joomla.sql
# 匯入 gzip 壓縮的備份檔
gzip -dc joomla.sql.gz | docker-compose exec db mysql -u root joomla
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