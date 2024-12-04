# [RabbitMQ](https://www.rabbitmq.com/) 訊息佇列伺服器

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 下載所需的容器映像檔
podman-compose pull

# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟管理介面, 預設的帳號與密碼皆為 guest
npx open-cli http://localhost:15672
```

## [啟用 TLS 加密連線](https://www.rabbitmq.com/docs/ssl)

### 建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `*.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkcert -cert-file ./cert.pem -key-file ./key.pem '*.dev.local' localhost

# 產生 Podman secrets
podman secret create --replace dev.local.key ./key.pem
podman secret create --replace dev.local.crt ./cert.pem
```

```sh
# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose up -d

# 確認已正確啟用
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose exec rabbitmq rabbitmq-diagnostics listeners
```

## [管理工具](https://www.rabbitmq.com/docs/cli)

以下示範如何使用 `rabbitmq` 容器本身的管理工具

> 執行前請先啟動資料庫服務

```sh
# 進入容器的 Bash Shell
podman-compose exec rabbitmq bash

# 顯示服務狀態
rabbitmqctl status

# 顯示所有連線
rabbitmqctl list_connections

# 顯示所有交換器
rabbitmqctl list_exchanges

# 顯示所有頻道
rabbitmqctl list_channels

# 顯示所有佇列
rabbitmqctl list_queues

# 清空指定佇列
rabbitmqctl purge_queue demo

# 調整日誌等級, 預設為 info
# https://rabbitmq.com/docs/logging/
rabbitmqctl set_log_level debug

# 顯示所有擴充套件
rabbitmq-plugins list

# 啟用指定擴充套件
rabbitmq-plugins enable rabbitmq_top
```
