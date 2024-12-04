# [Whoami 網路請求診斷工具](https://github.com/traefik/whoami)

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟瀏覽器顯示 HTTP 請求資訊
npx open-cli http://localhost:8080

# 以 JSON 型式顯示 HTTP 請求資訊
curl -sS http://localhost:8080/api | jq
```
