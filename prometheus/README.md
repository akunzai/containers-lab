# [Prometheus](https://prometheus.io/) 開發環境 for Docker

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)

## 運行開發環境

> `docker-compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行
>
> 可透過建立 `docker-compose.override.yml` 來擴展 `docker-compose.yml` 組態
>
> 還可以利用 [COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file) 環境變數指定多個組態來擴展服務配置

```sh
# 啟動並執行完整應用
docker-compose up

# 在背景啟動並執行完整應用
docker-compose up -d

# 在背景啟動並執行指定服務
docker-compose up -d prometheus

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
mkdir -p traefik/etc/ssl
mkcert -cert-file traefik/etc/ssl/cert.pem -key-file traefik/etc/ssl/key.pem '*.example.test'
```

配置完成 SSL 憑證後，可修改 `docker-compose.yml` 並加入 TLS 檔案配置以啟用 HTTPS 連線

```sh
mkdir -p traefik/etc/dynamic
cat <<EOF > traefik/etc/dynamic/tls.yml
tls:
  stores:
    default:
      defaultCertificate:
        certFile: /etc/traefik/ssl/cert.pem
        keyFile: /etc/traefik/ssl/key.pem
EOF
```

## [Exporters](https://prometheus.io/docs/instrumenting/exporters/)

- [Node/system metrics exporter](https://github.com/prometheus/node_exporter)
- [Windows exporter](https://github.com/prometheus-community/windows_exporter)
- [Blackbox exporter](https://github.com/prometheus/blackbox_exporter)
- [cAdvisor](https://github.com/google/cadvisor)

## [Dashboards](https://grafana.com/grafana/dashboards)

請透過 Grafana 管理介面的 Dashboards -> Manage -> Import 功能進行匯入

- [Node exporter](https://grafana.com/grafana/dashboards/10180)
- [Windows exporter](https://grafana.com/grafana/dashboards/13261)
- [Blackbox exporter](https://grafana.com/grafana/dashboards/11529)
- [cAdvisor](https://grafana.com/grafana/dashboards/12831)

## [Plugins](https://grafana.com/grafana/plugins)

```sh
# 可在啟動 grafana 容器後，透過 grafana-cli 指令安裝 plugin
docker-compose exec grafana grafana-cli plugins install grafana-piechart-panel
```

## 疑難排解

### [重新載入 Prometheus 配置](https://prometheus.io/docs/prometheus/latest/management_api/)

```sh
# 透過 docker-compose
docker-compose kill -s SIGHUP prometheus

# 透過 CURL
curl -X POST http://prometheus.example.test/-/reload
```

### [smtp.plainAuth failed: unencrypted connection](https://github.com/prometheus/alertmanager/issues/1358)

這是因為 Go 的 SMTP 套件實作不允許透過未加密的連線進行認證, 請改用不需要認證的 SMTP Relay 或是改用有支援加密的 SMTP 伺服器配置
