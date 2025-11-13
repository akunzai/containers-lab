# [Nessus](https://thekelleys.org.uk/dnsmasq/doc.html) 網站弱點掃描工具

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 下載所需的容器映像檔
podman-compose pull

# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟管理介面, 預設的帳號與密碼皆為 admin
npx open-cli https://localhost:8834
```
