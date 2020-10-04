# [Tomcat](https://github.com/microsoft/tomcat) 開發環境 for Docker

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
docker-compose up -d --scale tomcat=2

# 在背景啟動並執行指定服務
docker-compose up -d tomcat

# 顯示記錄
docker-compose logs

# 持續顯示記錄
docker-compose logs -f

# 關閉應用
docker-compose down

# 顯示所有啟動中的容器
docker ps

# 如果需要使用最新版本的 Tomcat 及 Java 執行環境的話
COMPOSE_FILE=docker-compose.yml:docker-compose.latest.yml docker-compose up -d

# 如果需要偵錯 Tomcat 容器內的應用程式的話
COMPOSE_FILE=docker-compose.yml:docker-compose.debug.yml docker-compose up -d
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 80: HTTP
- 8080: Traefik 負載平衡器管理後台

## 建立本機開發用的 SSL 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 SSL 憑證

以網域名稱 `*.example.test` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 SSL 憑證
mkdir -p traefik/conf/ssl
mkcert -cert-file traefik/conf/ssl/cert.pem -key-file traefik/conf/ssl/key.pem '*.example.test'
```

### 啟用 HTTPS 連線

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

如果啟用 HTTPS 後, 如果應用程式無法正確判定 HTTPS 安全連線的話

可以試著在 Tomcat 伺服器配置加入 [RemoteIPValve](https://tomcat.apache.org/tomcat-8.5-doc/config/valve.html#Remote_IP_Valve)

```diff
<Server port="8005" shutdown="SHUTDOWN">
  <Service name="Catalina">
    <Engine name="Catalina" defaultHost="localhost">
      <Host name="localhost" name="localhost" appBase="${site.home}/site/wwwroot/webapps" xmlBase="${site.home}/site/wwwroot/"
            unpackWARs="false" autoDeploy="true" workDir="${site.tempdir}">
+       <Valve className="org.apache.catalina.valves.RemoteIpValve" />
    </Engine>
  </Service>
</Server>
```

## 利用容器執行指令

```sh
# 預設執行身份為 root
$ docker-compose run --rm tomcat whoami
root

# 指定執行身份為 www-data
$ docker-compose run --rm --user www-data tomcat whoami
www-data

# 執行 Bash Shell
$ docker-compose run --rm tomcat bash
```

## [應用程式部署](https://docs.microsoft.com/azure/app-service/deploy-zip#deploy-war-file)

WAR 應用程式部署目錄為容器內的 `/home/site/wwwroot/webapps/`

如果希望將 WAR 應用程式透過 API 直接部署至 Azure App Service

```sh
curl -X POST -u <username> --data-binary @"<war-file-path>" https://<app-name>.scm.azurewebsites.net/api/wardeploy
```

## 自訂和調整

如需自訂 Tomcat 配置, 請複製必要的檔案至 `/home/tomcat` 目錄下,
Tomcat 會將 [CATALINA_BASE](https://tomcat.apache.org/tomcat-8.5-doc/introduction.html#CATALINA_HOME_and_CATALINA_BASE) 重設為 `/home/tomcat`，並使用自訂的配置

```sh
mkdir -p /home/tomcat/bin /home/tomcat/conf/ home/tomcat/lib /home/tomcat/temp
cp -v /usr/local/tomcat/bin/setenv.sh /usr/local/tomcat/bin/tomcat-juli.jar /home/tomcat/bin/
cp -v /usr/local/tomcat/lib/azure.*.jar /home/tomcat/lib/
cp -v /usr/local/tomcat/conf/* /home/tomcat/conf/
```

### [自訂啟動腳本](https://github.com/Azure-App-Service/tomcat/blob/dev/shared/misc/init_container.sh)

在本機開發時可以透過 [command](https://docs.docker.com/compose/compose-file/#command) 屬性設定啟動命令

而在 Azure App Service 則可以在組態頁面的一般設定中設定啟動命令

> 如果存在 `/home/startup.sh` 腳本, 將會自動於容器啟動時執行

### [設定 Java 執行階段選項](https://docs.microsoft.com/azure/app-service/configure-language-java#set-java-runtime-options)

如需設定 Java 執行階段選項, 可透過配置 `JAVA_OPTS` 環境變數達成，例如

```sh
JAVA_OPTS=-server -Xmx4g
```
