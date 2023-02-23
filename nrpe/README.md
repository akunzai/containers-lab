# Nagios [NRPE](https://github.com/NagiosEnterprises/nrpe) 遠端外掛監控工具

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## 使用方式

> `docker compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行
>
> 可透過建立 `docker-compose.override.yml` 來擴展 `docker-compose.yml` 組態
>
> 還可以利用 [COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file) 環境變數指定多個組態來擴展服務配置

```sh
# 啟動並執行完整應用
docker compose up

# 在背景啟動並執行完整應用
docker compose up -d

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

- 5666: NRPE (Nagios)

## 來源 IP 白名單配置

請參考 `docker-compose.yml` 範例設定環境變數 `ALLOWED_HOSTS` 的值，多個 IP 以逗號分隔。

## 監控 / 以外的檔案系統

以監控宿主的 `/opt` 目錄為例

請在 `docker-compose.yml` 中新增 volumes 的路徑對應 `/opt:/opt:ro`

再調整 `nrpe.cfg` 中的參數如下，最後重啟容器即可

```sh
command[check_disk]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /rootfs /opt
```
