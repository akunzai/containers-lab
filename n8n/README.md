# [n8n](https://n8n.io/) 工作流程自動化平台

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟 n8n 管理後台
npx open-cli http://localhost:5678
```

## 疑難排解

### 重設加密金鑰

若遺失 `N8N_ENCRYPTION_KEY`, 已儲存的認證資訊將無法解密, 需重新設定所有憑證

```sh
# 查看目前資料目錄內容
podman-compose exec n8n ls /home/node/.n8n
```
