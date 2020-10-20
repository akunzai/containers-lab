# .NET 開發環境 for Docker

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)

## 運行開發環境

> `docker-compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行
>
> 可透過建立 `docker-compose.override.yml` 來擴展 `docker-compose.yml` 組態
>
> 還可以利用 [COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file) 環境變數指定多個組態來擴展服務配置

```sh
# 啟動並執行完整應用(若配置有異動會自動重建容器)
docker-compose up

# 在背景啟動並執行完整應用
docker-compose up -d

# 在背景啟動應用時指定服務的執行個數數量
docker-compose up -d --scale dotnet=2

# 在背景啟動並執行指定服務
docker-compose up -d dotnet

# 顯示記錄
docker-compose logs

# 持續顯示記錄
docker-compose logs -f

# 關閉應用
docker-compose down

# 顯示所有啟動中的容器
docker ps
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 80: HTTP
- 8080: Traefik 負載平衡器管理後台

## [啟用 HTTPS 連線](https://doc.traefik.io/traefik/https/tls/)

### [使用 Let's Encrypt 自動產生憑證](https://doc.traefik.io/traefik/https/acme/)

### 建立本機開發用的 SSL 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 SSL 憑證

以網域名稱 `*.example.test` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 SSL 憑證
mkdir -p traefik/conf/ssl
mkcert -cert-file traefik/conf/ssl/cert.pem -key-file traefik/conf/ssl/key.pem '*.example.test'
```

配置完成 SSL 憑證後，可修改 `docker-compose.yml` 並加入 TLS 檔案配置以啟用 HTTPS 連線

```sh
mkdir -p traefik/conf/dynamic
cat <<EOF > traefik/conf/dynamic/tls.yml
tls:
  stores:
    default:
      defaultCertificate:
        certFile: /etc/traefik/ssl/cert.pem
        keyFile: /etc/traefik/ssl/key.pem
EOF
```

## 利用容器執行指令

```sh
# 預設執行身份為 root
$ docker-compose run --rm dotnet whoami
root

# 指定執行身份為 www-data
$ docker-compose run --rm --user www-data dotnet whoami
www-data

# 執行 Bash Shell
$ docker-compose run --rm dotnet bash
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
