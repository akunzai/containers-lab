# [Java](https://github.com/microsoft/java) 開發環境 for Docker

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## 運行開發環境

> `docker compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行
>
> 可透過建立 `docker-compose.override.yml` 來擴展 `docker-compose.yml` 組態
>
> 還可以利用 [COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file) 環境變數指定多個組態來擴展服務配置

```sh
# 啟動並執行完整應用(若配置有異動會自動重建容器)
docker compose up

# 在背景啟動並執行完整應用
docker compose up -d

# 在背景啟動應用時指定服務的執行個數數量
docker compose up -d --scale java=2

# 在背景啟動並執行指定服務
docker compose up -d java

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
mkdir -p traefik/etc/ssl
mkcert -cert-file traefik/etc/ssl/cert.pem -key-file traefik/etc/ssl/key.pem '*.example.test'
```

配置完成 SSL 憑證後，可修改 `docker-compose.yml` 並加入 TLS 檔案配置以啟用 HTTPS 連線

```sh
mkdir -p traefik/etc/dynamic
cat <<EOF > traefik/etc/dynamic/tls.yml
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
# 預設執行身分為 root
$ docker compose run --rm java whoami
root

# 指定執行身分為 www-data
$ docker compose run --rm --user www-data java whoami
www-data

# 執行 Bash Shell
$ docker compose run --rm java bash
```

## [應用程式部署](https://docs.microsoft.com/azure/app-service/configure-language-java?pivots=platform-linux#configure-jar-applications)

> 如果不希望更名 JAR 應用程式，則需要自訂容器的啟動程序

JAR 應用程式請打包或更名為 `app.jar` 並部署至容器內的 `/home/site/wwwroot/` 目錄下

## [自訂和調整](https://docs.microsoft.com/azure/app-service/configure-language-java?pivots=platform-linux#customization-and-tuning)

### [自訂啟動腳本](https://github.com/Azure-App-Service/java/blob/dev/shared/init_container.sh)

在本機開發時可以透過 [command](https://docs.docker.com/compose/compose-file/#command) 屬性設定啟動命令

而在 Azure App Service 則可以在組態頁面的一般設定中設定啟動命令

> 如果存在 `/home/startup.sh` 腳本, 將會自動於容器啟動時執行
>
> 但若設定啟動命令或腳本則不會載入預設的 jar

### [設定 Java 執行階段選項](https://docs.microsoft.com/azure/app-service/configure-language-java?pivots=platform-linux#set-java-runtime-options)

如需設定 Java 執行階段選項, 可透過配置 `JAVA_OPTS` 環境變數達成，例如

```sh
JAVA_OPTS=-server -Xmx4g
```

### [Spring Boot 應用程式組態檔配置](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config)

如需自訂 Spring Boot 應用程式組態檔位置

```sh
# 透過 Java 屬性自訂組態檔搜尋路徑 (多個路徑以逗號分隔, 後者會優先於前者)
JAVA_OPTS=-Dspring.config.location=classpath:/,file:/home/config/

# 透過環境變數自訂組態檔搜尋路徑 (多個路徑以逗號分隔, 後者會優先於前者)
SPRING_CONFIG_LOCATION=classpath:/,file:/home/config/
```

常用的 Spring Boot 應用程式組態檔配置如下表所示

| 名稱                              | 說明                                                                                                                                |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| spring.config.name                | 組態檔主檔名(用於切換組態, 會嘗試 `.properties` 及 `.yml`,`.yaml` 等副檔案, 預設值: `application`)                                  |
| spring.config.location            | 組態檔搜尋路徑(用於切換組態, 路徑必須以 `/` 結尾, 預設值: `classpath:/,classpath:/config/,file:./,file:./config/*/,file:./config/`) |
| spring.config.additional-location | 額外組態檔的搜尋路徑(用於覆寫組態, 自 2.0 開始支援)                                                                                 |
| spring.config.import              | 額外組態檔的匯入位址(用於覆寫組態, 自 2.4 開始支援)                                                                                 |

## 疑難排解

### [偵錯應用程式](https://www.baeldung.com/spring-debugging)

請配置如下的 `JAVA_OPTS` 環境變數，並開放連接埠 5005 以利偵錯

- JAVA_OPTS: `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005`

### 如果啟用 HTTPS 後, 如果應用程式無法正確判定 HTTPS 安全連線的話

可以試著在 Spring Boot JAR 應用程式組態檔加入以下配置以支援 [反向代理的 HTTPS 卸載](https://docs.spring.io/spring-boot/docs/current/reference/html/howto.html#howto-use-behind-a-proxy-server)

```ini:application.properties
# before spring-boot 2.2
server.use-forward-headers=true
# since spring-boot 2.2
server.forward-headers-strategy=NATIVE
```

### 以非 root 身分執行應用程式

可利用先前提到的自訂啟動腳本，在容器內透過 [gosu](https://github.com/tianon/gosu) 或 [su-exec](https://github.com/ncopa/su-exec) 等工具以非 root 身分執行應用程式

```sh
# for Debian/Ubuntu
apt-get update -qq && apt-get install --no-install-recommends -yqq gosu
gosu www-data java -noverify -Djava.security.egd=file:/dev/./urandom $JAVA_OPTS -jar $JAR_FILE

# for Alpine
apk update && apk add su-exec
su-exec nobody java -noverify -Djava.security.egd=file:/dev/./urandom $JAVA_OPTS -jar $JAR_FILE
```

某些內嵌 Tomcat 應用程式可能會[指定不同的工作目錄](https://github.com/apereo/cas/blob/6.4.x/webapp/cas-server-webapp-resources/src/main/resources/application.properties#L24)
當由 root 身分轉換至非 root 身分時，需一併自動建立這些目錄及設定好權限，否則可能會造成應用程式啟動失敗 (Unable to create the directory [/build/tomcat] to use as the base directory)

```sh
# ensure embedded tomcat working directory exists and fixes permission
mkdir -p /build/tomcat && chown -R www-data:www-data /build/tomcat
```
