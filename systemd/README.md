# systemd 服務管理器

在容器內運行 systemd 服務管理器

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## Getting Started

```sh
# 建置指定服務的映像檔
podman compose build debian

# 在背景啟動並執行指定服務
podman compose up -d debian

# 驗證容器內的 systemd 服務可正常執行
podman compose exec debian systemctl list-units

# 關閉應用
podman compose down
```

## 已知問題

- 在 macOS with Apple Silicon 的環境下無法正常啟動 systemd 服務
