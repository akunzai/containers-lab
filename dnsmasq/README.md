# [Dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html) 輕量級 DNS 伺服器

## 環境需求

- [Docker Engine](https://www.docker.com/) >= 25.0

## Getting Started

```sh
# 在背景啟動並執行完整應用
docker compose up -d

# 透過 dig 測試解析 /etc/hosts 中的主機名稱
dig www.dev.local @localhost
```
