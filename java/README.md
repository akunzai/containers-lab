# Java 開發環境 for Docker

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)

## 運行開發環境

> `docker-compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行
>
> 可透過建立 `docker-compose.override.yml` 來擴展 `docker-compose.yml` 組態
>
> 還可以利用 [COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file) 環境變數指定多個組態來擴展服務配置

```sh
# 啟動並執行完整應用
docker-compose up

# 在背景啟動並執行完整應用
docker-compose up -d

# 在背景啟動並執行指定服務
docker-compose up -d java

# 顯示記錄
docker-compose logs

# 持續顯示記錄
docker-compose logs -f

# 關閉應用
docker-compose down

# 顯示所有啟動中的容器
docker ps

# 如果需要擴展以啟用 OpenLDAP 服務的話
COMPOSE_FILE=docker-compose.yml:docker-compose.openldap.yml docker-compose up -d

# 如果需要擴展以啟用 Redis 服務的話
COMPOSE_FILE=docker-compose.yml:docker-compose.redis.yml docker-compose up -d

# 如果需要擴展以使用 Tomcat 執行環境的話
COMPOSE_FILE=docker-compose.yml:docker-compose.tomcat.yml docker-compose up -d
```

## 連線埠配置

啟動環境後預設會開始監聽本機的以下連線埠

- 80: HTTP

## 自訂網站負載平衡設定

請擴展 [HAProxy](https://www.haproxy.org/) 服務配置及調整 `etc/haproxy/haproxy.cfg`

調整後可以透過以下指令在不中斷服務的情況下重新載入組態

```sh
docker-compose kill -s HUP haproxy
```

### 啟用 HTTPS 連線

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 SSL 憑證

以網域名稱 `*.example.test` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 SSL 憑證
mkcert -cert-file etc/haproxy/cert.pem -key-file key.pem '*.example.test'
cat key.pem >> etc/haproxy/cert.pem && rm key.pem
```

如果啟用 HTTPS 後, 如果應用程式無法正確判定 HTTPS 安全連線的話

可以試著在 Spring Boot JAR 應用程式組態檔加入以下配置以[支援反向代理的 HTTPS 卸載](https://docs.spring.io/spring-boot/docs/current/reference/html/howto.html#howto-use-behind-a-proxy-server)

```ini:application.properties
# before spring-boot 2.2
server.use-forward-headers=true
# since spring-boot 2.2
server.forward-headers-strategy=NATIVE
```

或是自訂 Tomcat 伺服器配置加入 [RemoteIPValve](https://tomcat.apache.org/tomcat-8.5-doc/config/valve.html#Remote_IP_Valve)

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
$ docker-compose run --rm java whoami
root

# 指定執行身份為 www-data
$ docker-compose run --rm --user www-data java whoami
www-data

# 執行 Bash Shell
$ docker-compose run --rm java bash
```

## [自訂和調整](https://docs.microsoft.com/azure/app-service/containers/configure-language-java#customization-and-tuning)

### [設定 Java 執行階段選項](https://docs.microsoft.com/azure/app-service/containers/configure-language-java#set-java-runtime-options)

如需設定 Java 執行階段選項, 可透過配置 `JAVA_OPTS` 環境變數達成，例如

```sh
JAVA_OPTS=-Dfile.encoding=UTF-8
```

### [JAR 應用程式部署](https://docs.microsoft.com/azure/app-service/containers/configure-language-java#configure-jar-applications)

> 如果不希望更名 JAR 應用程式，則需要自訂容器的啟動程序

JAR 應用程式請打包或更名為 `app.jar` 並部署至容器內的 `/home/site/wwwroot/` 目錄下

### [WAR 應用程式部署](https://docs.microsoft.com/zh-tw/azure/app-service/deploy-zip#deploy-war-file)

如果希望將 WAR 應用程式透過 API 直接部署至 Azure App Service

```sh
curl -X POST -u <username> --data-binary @"<war-file-path>" https://<app-name>.scm.azurewebsites.net/api/wardeploy
```

如果希望將 WAR 應用程式部署至本機開發環境，則請先擴展以使用 Tomcat 執行環境

WAR 應用程式部署目錄為容器內的 `/home/site/wwwroot/webapps/`

如需自訂 Tomcat 配置, 請複製必要的檔案至 `/home/tomcat` 目錄下,
Tomcat 會將 [CATALINA_BASE](https://tomcat.apache.org/tomcat-8.5-doc/introduction.html#CATALINA_HOME_and_CATALINA_BASE) 重設為 `/home/tomcat`，並使用自訂的配置

```sh
mkdir -p /home/tomcat/bin /home/tomcat/temp
cp /usr/local/tomcat/bin/setenv.sh /home/tomcat/bin/
cp -r /usr/local/tomcat/conf /usr/local/tomcat/lib  /home/tomcat/
```

### [Spring Boot 應用程式組態檔配置](https://docs.spring.io/spring-boot/docs/current/reference/html/howto.html#howto-change-the-location-of-external-properties)

如需自訂 Spring Boot 應用程式組態檔位置

```sh
# 透過 Java 屬性自訂組態檔搜尋路徑
JAVA_OPTS=-Dspring.config.location=file:/home/config/
# 透過環境變數自訂組態檔搜尋路徑
SPRING_CONFIG_LOCATION=file:/home/config/
```

常用的 Spring Boot 應用程式組態檔配置如下表所示

| Java 屬性               | 環境變數                | 說明                                                       | 預設值                                                  |
| ----------------------- | ----------------------- | ---------------------------------------------------------- | ------------------------------------------------------- |
| spring.config.name      | SPRING_CONFIG_NAME      | 組態檔主檔名(會嘗試 `.properties` 及 `.(yml|yaml)` 副檔案) | `application`                                           |
| spring.config.location  | SPRING_CONFIG_LOCATION  | 逗號分隔的組態檔搜尋路徑(路徑必須以 `/` 結尾)              | `classpath:/,classpath:/config/,file:./,file:./config/` |
| spring.profiles.active  | SPRING_PROFILES_ACTIVE  | 逗號分隔的啟用配置名稱                                     |                                                         |
| spring.profiles.include | SPRING_PROFILES_INCLUDE | 逗號分隔的引用配置名稱                                     |                                                         |

## 偵錯應用程式

如需偵錯 Java 容器內的應用程式可以參考 `docker-compose.debug.yml` 的擴展

```sh
COMPOSE_FILE=docker-compose.yml:docker-compose.debug.yml docker-compose up
```
