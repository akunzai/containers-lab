# Java 開發環境

## 環境需求

- [Podman](https://podman.io/) >= 4.8.0
- [Podman Compose](https://github.com/containers/podman-compose) >= 1.2.0

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 開啟網站
npx open-cli http://localhost:8080
```

## [啟用 HTTPS 連線](https://docs.spring.io/spring-boot/docs/current/reference/html/howto.html#howto.webserver.configure-ssl)

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 TLS 憑證

以網域名稱 `*.dev.local` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 TLS 憑證
mkcert -cert-file ./cert.pem -key-file ./key.pem '*.dev.local' localhost

# 產生 Podman secrets
podman secret create --replace dev.local.key ./key.pem
podman secret create --replace dev.local.crt ./cert.pem

# 啟用 TLS 加密連線
COMPOSE_FILE=compose.yml:compose.tls.yml podman-compose up -d

# 確認已正確啟用
curl -v 'https://www.dev.local:8443'
```

## 利用容器執行指令

```sh
# 預設執行身分為 www-data
$ podman-compose run --rm java whoami
www-data

# 指定執行身分為 root
$ podman-compose run --rm --user root java whoami
root

# 進入 Shell 互動環境
$ podman-compose run --rm java bash
```

## [Spring Boot 應用程式組態檔配置](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config)

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

> 如果 JVM 版本小於 9, address 參數請改為 5005

- JAVA_OPTS: `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005`

### 如果啟用 HTTPS 後, 如果應用程式無法正確判定 HTTPS 安全連線的話

可以試著在 Spring Boot JAR 應用程式組態檔加入以下配置以支援 [反向代理的 HTTPS 卸載](https://docs.spring.io/spring-boot/docs/current/reference/html/howto.html#howto-use-behind-a-proxy-server)

```ini:application.properties
# before spring-boot 2.2
server.use-forward-headers=true
# since spring-boot 2.2
server.forward-headers-strategy=NATIVE
```

如果你使用的反向代理伺服器並不是使用預設的信任 IP 範圍的話

> Java properties 檔案需要跳脫特殊字元，若使用其它配置形式可將 `\\` 替換為 `\`

```ini:application.properties
server.tomcat.remoteip.trusted-proxies=198\\.19\\.\\d{1,3}\\.\\d{1,3}|35\\.191\\.\\d{1,3}\\.\\d{1,3}
```
