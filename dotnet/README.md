# .NET 執行環境

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## 使用方式

> `docker compose` 指令必須要在 `compose.yml` 所在的目錄下執行
>
> 可透過建立 `compose.override.yml` 來擴展 `compose.yml` 組態
>
> 還可以利用 [COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file) 環境變數指定多個組態來擴展服務配置

```sh
# 啟動並執行完整應用(若配置有異動會自動重建容器)
docker compose up

# 在背景啟動並執行完整應用
docker compose up -d

# 在背景啟動應用時指定服務的執行個數數量
docker compose up -d --scale dotnet=2

# 在背景啟動並執行指定服務
docker compose up -d dotnet

# 顯示記錄
docker compose logs

# 持續顯示記錄
docker compose logs -f

# 關閉應用
docker compose down

# 顯示所有啟動中的容器
docker ps
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 80: HTTP
- 9090: Traefik 負載平衡器管理後台

## [啟用 HTTPS 連線](https://doc.traefik.io/traefik/https/tls/)

### [使用 Let's Encrypt 自動產生憑證](https://doc.traefik.io/traefik/https/acme/)

### 建立本機開發用的 TLS 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `*.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkdir -p certs
mkcert -cert-file certs/cert.pem -key-file certs/key.pem '*.dev.local'
```

配置完成 TLS 憑證後，可修改 `compose.yml` 並加入 TLS 檔案配置以啟用 HTTPS 連線

```sh
mkdir -p traefik/etc/dynamic
cat <<EOF > traefik/etc/dynamic/tls.yml
tls:
  options:
    default:
      minVersion: VersionTLS12
  stores:
    default:
      defaultCertificate:
        certFile: /etc/traefik/certs/cert.pem
        keyFile: /etc/traefik/certs/key.pem
EOF
```

## 利用容器執行指令

```sh
# 預設執行身分為 root
$ docker compose run --rm dotnet whoami
root

# 指定執行身分為 www-data
$ docker compose run --rm --user www-data dotnet whoami
www-data

# 執行 Bash Shell
$ docker compose run --rm dotnet bash
```

## 應用程式部署

請將 ASP.NET Core 應用程式部署至容器內的 `/home/site/wwwroot/` 目錄下

```sh
mkdir -p ./home/site/wwwroot
dotnet publish -c Release -o ./home/site/wwwroot/
```

再自訂啟動命令以執行主要的 ASP.NET Core 應用程式, 例如: `dotnet /home/site/wwwroot/myapp.dll`

在本機開發時可以透過 [command](https://docs.docker.com/compose/compose-file/#command) 屬性設定啟動命令

而在 Azure App Service 則可以在組態頁面的一般設定中設定啟動命令

## 以非 root 身分執行應用程式

可利用自訂啟動腳本，在容器內透過 [gosu](https://github.com/tianon/gosu) 工具以非 root 身分執行應用程式

```sh
apt-get update -qq && apt-get install --no-install-recommends -yqq gosu
gosu www-data dotnet /home/site/wwwroot/myapp.dll
```
