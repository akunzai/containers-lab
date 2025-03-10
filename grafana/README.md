# [](https://grafana.com/) 監控告警系統

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟 Prometheus 管理後台
npx open-cli http://localhost:9090

# 開啟 Grafana 管理後台, 預設的帳號與密碼皆為 admin
# > 如有開放外部存取請記得變更帳密
npx open-cli http://localhost:3000

# 開啟 Alertmanager 管理後台
npx open-cli http://localhost:9093
```

## [Dashboards](https://grafana.com/grafana/dashboards)

請透過 Grafana 管理介面的 Dashboards -> New -> Import 功能進行匯入

- [Blackbox exporter](https://grafana.com/grafana/dashboards/11529-blackbox-exporter-quick-overview/)
- [Cadvisor exporter](https://grafana.com/grafana/dashboards/14282-cadvisor-exporter/)
- [Node exporter](https://grafana.com/grafana/dashboards/10180-kds-linux-hosts/)
- [Prometheus](https://grafana.com/grafana/dashboards/12054-prometheus-benchmark-2-17-x/)
- [Windows exporter](https://grafana.com/grafana/dashboards/6593-windows-node/)
- [Logs / App](https://grafana.com/grafana/dashboards/13639-logs-app/)
- [Nginx access logs](https://grafana.com/grafana/dashboards/16101-grafana-loki-dashboard-for-nginx-service-mesh/)

## [Prometheus](https://prometheus.io/) 監控時序資料庫

### [Prometheus 監控數據匯出](https://prometheus.io/docs/instrumenting/exporters/)

- [Blackbox exporter](https://github.com/prometheus/blackbox_exporter)
- [cAdvisor](https://github.com/google/cadvisor)
- [SNMP exporter](https://github.com/prometheus/snmp_exporter)
- [SQL exporter](https://github.com/burningalchemist/sql_exporter)
- [Node exporter](https://github.com/prometheus/node_exporter)
- [Redis exporter](https://github.com/oliver006/redis_exporter)
- [Windows exporter](https://github.com/prometheus-community/windows_exporter)

## [Loki](https://github.com/grafana/loki) 日誌資料庫

### [查詢記錄檔](https://grafana.com/docs/loki/latest/getting-started/grafana/)

請透過 Grafana 管理介面側邊列的 Explore, 選擇 Loki 資料來源

再選取記錄檔串流查詢記錄

> 可使用 [LogQL](https://grafana.com/docs/loki/latest/logql/) 查詢語法

### [記錄檔收集](https://grafana.com/docs/loki/latest/send-data/)

Grafana Loki 支援透過許多不用的用戶端來收集記錄檔

- [Promtail](https://grafana.com/docs/loki/latest/clients/promtail/)
- [Grafana Alloy](https://grafana.com/docs/loki/latest/send-data/alloy/)
- [OpenTelemetry](https://grafana.com/docs/loki/latest/send-data/otel/)
- [Docker driver](https://grafana.com/docs/loki/latest/clients/docker-driver/)
- [Fluentbit](https://grafana.com/docs/loki/latest/clients/fluentbit/)
- [Fluentd](https://grafana.com/docs/loki/latest/clients/fluentd/)

## 疑難排解

### 重載組態配置

```sh
# 透過 podman-compose
podman-compose kill -s SIGHUP prometheus loki

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
