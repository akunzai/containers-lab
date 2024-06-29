# [Central Authentication Service (CAS)](https://github.com/apereo/cas) 開源身分驗證服務

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## Getting Started

```bash
# 下載所需的容器映像檔
docker pull apereo/cas:6.6.4

# 調整 /etc/cas/config/cas.properties 設定檔
- 設為自己的 IP 或 Domain
  - `cas.server.name`
- 改成自己的 key，其中 signing.key 長度有一定限制 (可使用：`openssl rand -hex 64` 指令產出)
  - `cas.ticket.registry.in-memory.crypto.encryption.key`
  - `cas.ticket.registry.in-memory.crypto.signing.key`

# 執行 `create-demo-ssl.ps1` 產生 SSL 憑證，執行後會在 `/etc/cas/config/` 目錄下看到 `server.keystore` 檔案
.\create-demo-ssl.ps1

# 在背景啟動並執行完整應用
docker-compose up -d
```

## Testing Started

``` bash
# 開啟登錄介面, 預設的帳號 `casuser` 與密碼為 `Mellon`
open browser http://127.0.0.1:8443/cas/login

# 測試 CAS 2.0 登入取得 ticket
open browser https://127.0.0.1:8443/cas/login?service=http%3A%2F%2F127.0.0.1%2FDemoSite
```

## Checking Started

- 測試 CAS 2.0 驗證 ticket
  - 驗證票證時間間隔須於 10 秒內，否則會得到 INVALID_TICKET 驗證失敗的錯誤

``` bash
open browser http://127.0.0.1:8443/cas/serviceValidate?service=http%3A%2F%2F127.0.0.1%2FDemoSite&ticket=ST-1-Zd9F-HIGRA9rHGqKB123vhDovTk-aa153bce8242
```

- 驗證成功後，會得到以下 XML 示意資訊

``` xml
<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
    <cas:authenticationSuccess>
        <cas:user>casuser</cas:user>
        <cas:attributes>
            <cas:credentialType>UsernamePasswordCredential</cas:credentialType>
            <cas:clientIpAddress>172.20.1.1</cas:clientIpAddress>
            <cas:isFromNewLogin>true</cas:isFromNewLogin>
            <cas:authenticationDate>2024-06-29T08:23:57.867704Z</cas:authenticationDate>
            <cas:authenticationMethod>Static Credentials</cas:authenticationMethod>
            <cas:successfulAuthenticationHandlers>Static Credentials</cas:successfulAuthenticationHandlers>
            <cas:serverIpAddress>172.20.1.2</cas:serverIpAddress>
            <cas:userAgent>Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/517.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36 Edg/126.0.0.0</cas:userAgent>
            <cas:longTermAuthenticationRequestTokenUsed>false</cas:longTermAuthenticationRequestTokenUsed>
            </cas:attributes>
    </cas:authenticationSuccess>
</cas:serviceResponse>
```
