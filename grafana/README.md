# [Grafana](https://grafana.com/) 監控告警系統

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 啟用偵錯模式
export COMPOSE_FILE=compose.yml:compose.debug.yml

# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟 Grafana 管理後台
npx open-cli http://localhost:3000

# 產生測試的 logs 至 alloy 的 OLTP 端點
podman-compose run otelgen --otel-exporter-otlp-endpoint alloy:4317 --insecure logs multi

# 產生測試的 metrics 至 alloy 的 OLTP 端點
podman-compose run otelgen --otel-exporter-otlp-endpoint alloy:4317 --insecure metrics sum
```

## [Dashboards](https://grafana.com/grafana/dashboards)

請透過 Grafana 管理介面的 Dashboards -> New -> Import 功能進行匯入

- [ASP.NET OTEL Metrics from OTEL Collector](https://grafana.com/grafana/dashboards/19896-asp-net-otel-metrics-from-otel-collector/)
- [Blackbox exporter](https://grafana.com/grafana/dashboards/11529-blackbox-exporter-quick-overview/)
- [Cadvisor exporter](https://grafana.com/grafana/dashboards/14282-cadvisor-exporter/)
- [Node exporter](https://grafana.com/grafana/dashboards/10180-kds-linux-hosts/)
- [Prometheus](https://grafana.com/grafana/dashboards/12054-prometheus-benchmark-2-17-x/)
- [Windows exporter](https://grafana.com/grafana/dashboards/6593-windows-node/)

## [Prometheus](https://prometheus.io/) 時序資料庫

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

Grafana Loki 支援透過許多不同的用戶端來收集記錄檔

- [Grafana Alloy](https://grafana.com/docs/loki/latest/send-data/alloy/)
- [OpenTelemetry](https://grafana.com/docs/loki/latest/send-data/otel/)
- [Vector](https://vector.dev/docs/reference/configuration/sinks/loki/)

## 疑難排解

### 重載組態配置

```sh
podman-compose kill -s SIGHUP prometheus loki
```

### 檢查 Prometheus 組態語法

```sh
podman-compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

### [smtp.plainAuth failed: unencrypted connection](https://github.com/prometheus/alertmanager/issues/1358)

這是因為 Go 的 SMTP 套件實作不允許透過未加密的連線進行認證, 請改用不需要認證的 SMTP Relay 或是改用有支援加密的 SMTP 伺服器配置

### [Datasource named ${DS_PROMETHEUS} was not found](https://community.grafana.com/t/grafana-as-code-provisioned-dashboard-do-not-recognize-datasource/83694)

請將要匯入 dashboard 內容中的 `${DS_PROMETHEUS}` 變數全部取代為 `Prometheus`
