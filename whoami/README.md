# [Whoami 網路請求診斷工具](https://github.com/traefik/whoami)

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## Getting Started

```sh
# 在背景啟動並執行完整應用
docker compose up -d

# 開啟瀏覽器顯示 HTTP 請求資訊
open http://localhost:8080

# 以 JSON 型式顯示 HTTP 請求資訊
curl -sS http://localhost:8080/api | jq
```
