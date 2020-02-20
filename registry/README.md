# 自建 [Docker Registry](https://docs.docker.com/registry/)

## 環境需求

- [Docker Engine](https://docs.docker.com/engine/installation/)

## 運行開發環境

> `docker-compose` 指令必須要在 `docker-compose.yml` 所在的目錄下執行

```sh
# 啟動並執行完整應用
docker-compose up

# 在背景啟動並執行完整應用
docker-compose up -d

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

- 5000: HTTP/HTTPS

> 請參考 `docker-compose.yml` 的內容做調整

## 建立本機開發用的 SSL 憑證

可透過 [mkcert](https://github.com/FiloSottile/mkcert) 建立本機開發用的 SSL 憑證

以網域名稱 `dev.registry.test` 為例

```sh
# 安裝本機開發用的憑證簽發證書
mkcert -install

# 產生 SSL 憑證
mkcert -cert-file etc/certs/domain.crt -key-file etc/certs/domain.key dev.registry.test
```

## 啟用 HTTPS 連線

配置完成 SSL 憑證後，可修改 `docker-compose.yml` 以啟用 HTTPS 連線

## 限制存取

> 應避免未限制存取就將自建的映像檔伺服器部署在公開的網路上

```sh
# 可透過 `htpasswd` 指令加入可存取 Registry 的帳密
docker run --rm --entrypoint htpasswd registry:2 -Bbn testuser testpassword > etc/auth/htpasswd

# 登入自建的 Registry
$ docker login dev.registry.test:5000
Username: testuser
Password:
Login Succeeded
```

## 測試

```sh
# 上傳映像檔專案至自建的 Registry
$ docker pull hello-world
$ docker tag hello-world dev.registry.test:5000/hello-world
$ docker push dev.registry.test:5000/hello-world

# 列出 Registry 上的所有映像檔專案
$ curl -ku testuser:testpassword https://dev.registry.test:5000/v2/_catalog
{"repositories":["hello-world"]}
```
