# [Grafana Loki](https://github.com/grafana/loki) 日誌收集系統

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

# 在背景啟動並執行指定服務
docker compose up -d loki

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

- 80: HTTP
- 8080: Traefik 負載平衡器管理後台
- 3100: Loki 記錄收集伺服器

## [啟用 HTTPS 連線](https://doc.traefik.io/traefik/https/tls/)

### [使用 Let's Encrypt 自動產生憑證](https://doc.traefik.io/traefik/https/acme/)

### 建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `*.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkdir -p traefik/etc
mkcert -cert-file traefik/etc/cert.pem -key-file traefik/etc/key.pem '*.dev.local'
```

配置完成 TLS 憑證後，可修改 `docker-compose.yml` 並加入 TLS 檔案配置以啟用 HTTPS 連線

```sh
mkdir -p traefik/etc/dynamic
cat <<EOF > traefik/etc/dynamic/tls.yml
tls:
  stores:
    default:
      defaultCertificate:
        certFile: /etc/traefik/cert.pem
        keyFile: /etc/traefik/key.pem
EOF
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

## 疑難排解

### 重新載入 Loki 配置

```sh
# 透過 docker compose
docker compose kill -s SIGHUP loki
```
