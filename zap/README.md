# [ZAP](https://www.zaproxy.org/) 網站弱點動態掃瞄工具

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 下載所需的容器映像檔
podman-compose pull

# 在背景啟動並執行完整應用
podman-compose up -d

# 使用瀏覽器開啟 ZAP Desktop UI 來動態掃瞄網站弱點
npx open-cli http://localhost:8080/zap
```

## 以命令列模式動態掃瞄網站弱點

```sh
# 以基本模式掃瞄指定網站弱點
podman run zaproxy/zap-stable zap-baseline.py -t https://www.example.com

# 以完整模式掃瞄指定網站弱點
podman run zaproxy/zap-stable zap-full-scan.py -t https://www.example.com

# 掃瞄指定 API, 支援 openapi, soap, graphql 等格式
podman run zaproxy/zap-stable zap-api-scan.py -t https://www.example.com/graphql -f graphql

# 產生 HTML 格式的掃瞄報表
podman run -v $(pwd):/zap/wrk/ zaproxy/zap-stable zap-full-scan.py -t https://www.example.com -r dast-report.html
```

## References

- [ZAP Docker Documentation](https://www.zaproxy.org/docs/docker/)
