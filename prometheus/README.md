# [Prometheus](https://prometheus.io/) 監控告警系統

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## 使用方式

> `podman-compose` 指令必須要在 `compose.yml` 所在的目錄下執行
>
> 可透過建立 `compose.override.yml` 來擴展 `compose.yml` 組態
>
> 還可以利用 [COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file) 環境變數指定多個組態來擴展服務配置

```sh
# 啟動並執行完整應用
podman-compose up

# 在背景啟動並執行完整應用
podman-compose up -d

# 在背景啟動並執行指定服務
podman-compose up -d prometheus

# 顯示記錄
podman-compose logs

# 持續顯示記錄
podman-compose logs -f

# 關閉應用
podman-compose down
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 3000: Grafana 管理後台
- 8080: cAdvisor 管理後台
- 9090: Prometheus 管理後台
- 9093: Alertmanager 管理後台

## [Exporters](https://prometheus.io/docs/instrumenting/exporters/)

- [Blackbox exporter](https://github.com/prometheus/blackbox_exporter)
- [cAdvisor](https://github.com/google/cadvisor)
- [SNMP exporter](https://github.com/prometheus/snmp_exporter)
- [SQL exporter](https://github.com/burningalchemist/sql_exporter)
- [Node exporter](https://github.com/prometheus/node_exporter)
- [Redis exporter](https://github.com/oliver006/redis_exporter)
- [Windows exporter](https://github.com/prometheus-community/windows_exporter)

## [Alertmanager webhook receiver](https://prometheus.io/docs/operating/integrations/#alertmanager-webhook-receiver)

- [LINE Notify Gateway](https://github.com/blakey22/line-notify-gateway)

## [Dashboards](https://grafana.com/grafana/dashboards)

請透過 Grafana 管理介面的 Dashboards -> New -> Import 功能進行匯入

- [Blackbox exporter](https://grafana.com/grafana/dashboards/11529-blackbox-exporter-quick-overview/)
- [Cadvisor exporter](https://grafana.com/grafana/dashboards/14282-cadvisor-exporter/)
- [Node exporter](https://grafana.com/grafana/dashboards/10180-kds-linux-hosts/)
- [Prometheus](https://grafana.com/grafana/dashboards/12054-prometheus-benchmark-2-17-x/)
- [Windows exporter](https://grafana.com/grafana/dashboards/6593-windows-node/)

## 疑難排解

### [重新載入 Prometheus 配置](https://prometheus.io/docs/prometheus/latest/management_api/)

```sh
# 透過 podman-compose
podman-compose kill -s SIGHUP prometheus

# 透過 CURL
curl -X POST http://prometheus.dev.local/-/reload
```

### 檢查 Prometheus 組態語法

```sh
podman-compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

### [smtp.plainAuth failed: unencrypted connection](https://github.com/prometheus/alertmanager/issues/1358)

這是因為 Go 的 SMTP 套件實作不允許透過未加密的連線進行認證, 請改用不需要認證的 SMTP Relay 或是改用有支援加密的 SMTP 伺服器配置

### 授權 SQL Server 使用者查看效能資訊

> 請視實際情況修改帳號密碼

```sql
-- 建立登入帳號
CREATE LOGIN [monitor] WITH PASSWORD = 'ChangeMe!!'

-- 切換資料庫至 master
USE [master]

-- 建立登入帳號對應的資料庫使用者
CREATE USER [monitor] FOR LOGIN [monitor]

-- 授權資料庫使用者查看伺服器狀態
GRANT VIEW SERVER STATE TO [monitor]
-- 授權資料庫使用者查看物件定義以查詢各資料庫的 IO 等待時間
GRANT VIEW ANY DEFINITION TO [monitor]
```
