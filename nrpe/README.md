# Nagios [NRPE](https://github.com/NagiosEnterprises/nrpe) 遠端外掛監控工具

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 測試連線
curl -v http://localhost:5666
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 5666: NRPE (Nagios)

## 來源 IP 白名單配置

請參考 `compose.yml` 範例設定環境變數 `ALLOWED_HOSTS` 的值，多個 IP 以逗號分隔。

## 監控 / 以外的檔案系統

以監控宿主的 `/opt` 目錄為例

請在 `compose.yml` 中新增 volumes 的路徑對應 `/opt:/opt:ro`

再調整 `nrpe.cfg` 中的參數如下，最後重啟容器即可

```sh
command[check_disk]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /rootfs /opt
```
