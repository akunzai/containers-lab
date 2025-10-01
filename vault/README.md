# [Vault](https://developer.hashicorp.com/vault) 私鑰與加密管理系統

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 下載所需的容器映像檔
podman-compose pull

# 在背景啟動並執行完整應用
podman-compose up -d

# 查看初始化資訊
podman-compose logs vault

# 開啟管理介面
npx open-cli http://localhost:8200
```
