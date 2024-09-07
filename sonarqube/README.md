# [SonarQube](https://docs.sonarsource.com/sonarqube/) 程式碼品質檢測平台

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## Getting Started

```sh
# 下載所需的容器映像檔
podman-compose pull

# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟管理介面, 預設的帳號與密碼皆為 admin
npx open-cli http://localhost:9000
```
