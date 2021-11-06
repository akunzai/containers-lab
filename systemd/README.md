# systemd for Docker

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## systemd 服務整合範例

```sh
# 建置指定服務的映像檔
docker compose build centos

# 在背景啟動並執行指定服務
docker compose up -d centos

# 驗證容器內的 systemd 服務可正常執行
docker compose exec centos systemctl list-units

# 關閉應用
docker compose down
```
