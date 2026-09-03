# [Vault](https://developer.hashicorp.com/vault) 私鑰與加密管理系統

在 Docker（非 Swarm 模式）環境下，原生 `secrets` 功能僅能讀取主機上的實體明文檔案，缺乏如 Podman secrets 原生將機密存放於記憶體（tmpfs）的保護機制。

本 Lab 示範透過 **HashiCorp Vault + Vault Agent Sidecar** 架構，在 Docker Compose 環境中實現與 Podman/Swarm secrets 等級的機密保護方案：

- **記憶體保護（明文不落地）**：透過 `tmpfs` 驅動的 Docker Volume，機密僅存在 RAM 中。
- **生命週期同步**：Vault Agent 於機密渲染完成後建立標記觸發 Healthcheck，確保應用容器啟動時機密已就緒。
- **動態映射與清理**：自動映射 Vault 中的 Key-Value 為 `/run/secrets/*` 檔案，支援熱更新與雙向刪除清理（Prune）。
- **非 Root 容器相容**：機密檔案權限支援可配置（預設 `0444`），相容 PostgreSQL 等以非 root 使用者執行的容器。

## 環境需求

- [Docker](https://www.docker.com/) >= 24.0.0
- [Docker Compose](https://docs.docker.com/compose/) >= 2.20.0

## Getting Started

```sh
# 下載所需的容器映像檔
docker compose pull

# 在背景啟動並執行完整應用
docker compose up -d

# 查看 App 容器讀取 /run/secrets 的即時日誌
docker compose logs -f app

# 查看 Vault 初始化與憑證資訊
docker compose logs vault

# 開啟 Vault Web 管理介面
npx open-cli http://localhost:8200
```

## 示範：對接真實資料庫 (PostgreSQL)

本 Lab 亦提供 `compose.postgres.yml` 疊加配置，示範在非 Swarm 的 Docker 環境下，官方 PostgreSQL 容器如何直接以 `POSTGRES_PASSWORD_FILE: /run/secrets/postgres.pwd` 安全開機：

```sh
# 啟動含 PostgreSQL 示範服務的堆疊
docker compose -f compose.yml -f compose.postgres.yml up -d

# 檢查 PostgreSQL 啟動狀態與密碼驗證日誌
docker compose -f compose.yml -f compose.postgres.yml logs -f postgres
```

## 機密管理與維運

### 預設機密種子

初始化腳本會在 `secret/app/` 下預先注入下列測試機密：

- `postgres.pwd`：`lab-secure-pg-pwd-2026`
- `api_key`：`vault-api-key-sample-value`

### 透過 CLI 新增或更新機密

```sh
# 進入 Vault 容器更新機密
docker compose exec -e VAULT_TOKEN="$(docker compose exec vault cat /vault/file/.vault-keys | grep VAULT_ROOT_TOKEN | cut -d= -f2)" vault \
  vault kv put secret/app/api_key value="new-secret-token-999"

# 觀察 App 容器偵測到熱更新
docker compose logs -f app
```
