# [Grafana Loki](https://github.com/grafana/loki) 日誌收集系統

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟 Grafana 管理後台, 預設的帳號與密碼皆為 admin
# > 如有開放外部存取請記得變更帳密
npx open-cli http://localhost:3000
```

## [查詢記錄檔](https://grafana.com/docs/loki/latest/getting-started/grafana/)

請透過 Grafana 管理介面側邊列的 Explore, 選擇 Loki 資料來源

再選取記錄檔串流查詢記錄

> 可使用 [LogQL](https://grafana.com/docs/loki/latest/logql/) 查詢語法

## [用戶端](https://grafana.com/docs/loki/latest/clients/)

Grafana Loki 支援許多用戶端應用程式來收集記錄檔

- [Promtail](https://grafana.com/docs/loki/latest/clients/promtail/)
- [Docker driver](https://grafana.com/docs/loki/latest/clients/docker-driver/)
- [Fluentbit](https://grafana.com/docs/loki/latest/clients/fluentbit/)
- [Fluentd](https://grafana.com/docs/loki/latest/clients/fluentd/)

## [Dashboards](https://grafana.com/grafana/dashboards)

請透過 Grafana 管理介面的 Dashboards -> New -> Import 功能進行匯入

- [Logs / App](https://grafana.com/grafana/dashboards/13639-logs-app/)
- [Nginx access logs](https://grafana.com/grafana/dashboards/16101-grafana-loki-dashboard-for-nginx-service-mesh/)

## 疑難排解

### 重新載入 Loki 配置

```sh
# 透過 podman-compose
podman-compose kill -s SIGHUP loki
```

### [自動整理 log 檔案](https://stackoverflow.com/q/49450422)

> [traefik 在接收到 USR1 訊號時會關閉重新開啟記錄檔](https://doc.traefik.io/traefik/observability/logs/#log-rotation)

```sh
sudo tee /etc/logrotate.d/traefik <<'EOF'
/var/log/traefik/*.log {
    daily
    rotate 180
    missingok
    notifempty
    compress
    dateext
    dateformat .%Y-%m-%d
    create 0644 root adm
    postrotate
      podman kill -s USR1 $(podman ps -qf name=traefik) >/dev/null 2>&1
    endscript
}
EOF

# 預設 logrotate 的安全性設計並不允許處理目錄權限不為 root:root 的檔案
sudo chown root:root /var/log/traefik/

# 測試執行
logrotate -d /etc/logrotate.d/traefik

# 實際執行
sudo logrotate -v /etc/logrotate.d/traefik
```
