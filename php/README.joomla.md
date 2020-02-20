# Joomla 開發環境 for Docker

## 還原網站的方法

1. 先利用 Akeeba Backup 元件或 Akeeba Solo 完整備份 Joomla 網站 並將壓縮檔放在 home 目錄下
2. 下載 [Akeeba Kickstart](https://www.akeebabackup.com/download.html) 並解壓縮至 home 目錄下
3. 利用瀏覽器開啟解壓縮的 [Kickstart 主頁面](http://127.0.0.1/kickstart.php)
4. 選取要還原的備份檔並選以解壓縮檔模式為 `Directly` 後開始進行解壓縮
5. 解壓縮完成後將開啟 [Kickstart 安裝頁面](http://127.0.0.1/installation/) 進行網站還原
6. 在資料庫還原階段, 資料庫主機名稱請設定為 db 即可使用 MariaDB 資料庫容器

    建議保留表格名稱前綴,否則會因為 Joomla 內部預設資料表前綴(`jos_`) 而找不到資料表

7. 網站還原完成後，回到 Kickstart 主頁面執行 Clean Up

    如果無法執行 Clean Up, 可以手動清理 home 目錄下的如下檔案及目錄
    - `kicketstart.php`
    - `en-GB.kickstart.ini`
    - `installation/`
    - `*.jpa`

## 開發環境調整

請修改 `home/configuration.php` 的 `$live_site` 值為開發時期使用的網址

```php
public $live_site = 'https://dev.joomla.test';
```