# 自建 [Docker Registry](https://docs.docker.com/registry/)

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)

## 運行開發環境

> `docker-compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行

可透過建立 `docker-compose.override.yml` 來擴展 `docker-compose.yml` 組態

```sh
# 啟動並執行完整應用(若配置有異動會自動重建容器)
docker-compose up

# 在背景啟動並執行完整應用
docker-compose up -d

# 在背景啟動應用時指定服務的執行個數數量
docker-compose up -d --scale registry=2

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

## 建立本機開發用的 SSL 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 SSL 憑證

以網域名稱 `registry.example.test` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 SSL 憑證
mkdir -p traefik/conf/ssl
mkcert -cert-file traefik/conf/ssl/cert.pem -key-file traefik/conf/ssl/key.pem 'registry.example.test'
```

## 啟用 HTTPS 連線

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

## [限制存取](https://doc.traefik.io/traefik/middlewares/basicauth/)

> 應避免未限制存取就將自建的映像檔伺服器部署在公開的網路上

```sh
# 可透過 basicauth 限制可登入存取 Registry 的帳號與密碼
echo $(htpasswd -nb user password) | sed -e s/\\$/\\$\\$/g

# 登入自建的 Registry
docker login registry.example.test
```

## 測試

```sh
# 上傳映像檔專案至自建的 Registry
docker pull hello-world
docker tag hello-world registry.example.test/hello-world
docker push registry.example.test/hello-world

# 列出 Registry 上的所有映像檔專案
$ curl -L http://registry.example.test/v2/_catalog
{"repositories":["hello-world"]}
```
