# [Squid](http://www.squid-cache.org/) 快取代理伺服器

可用來快取、監控或限制容器的對外連線

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## Getting Started

```sh
# 在背景啟動並執行 squid 容器
podman-compose up -d squid

# 持續監看運行中 squid 容器的存取記錄
podman-compose exec squid tail -f /var/log/squid/access.log
```

## [使用 squid 容器代理對外連線](https://docs.docker.com/network/proxy/)

請參見 `compose.yml` 中的範例

```sh
podman-compose run curl -vI http://example.com
```

## [調整 squid 容器組態配置](http://www.squid-cache.org/Doc/config/)

預設快取是儲存在記憶體內，如果要改成儲存在檔案系統上，請在 `squid.conf` 中加入以下組態

```ini
# http://www.squid-cache.org/Doc/config/cache_dir/
cache_dir aufs /var/spool/squid 100 16 256
```
