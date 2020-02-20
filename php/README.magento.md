# Magento 開發環境 for Docker

## 安裝 Magento

> 建議安裝 magento >= 1.9.3.9 的版本以[相容 PHP 7.2](https://inchoo.net/magento/magento-1-official-php-7-2-patches/)

```sh
# 直接至官網下載安裝檔後解壓縮
tar xvjf ./magento-1.9.4.4-2020-01-28-04-53-07.tar.bz2
[ -e "./home.orig" ] || mv ./home ./home.orig
mv -f ./magento ./home
# 可能需要重啟應用
docker-compose restart

# 或是以互動模式安裝 Magento
docker-compose run --rm cli n98-magerun install
```

## Magento 組態設定

將 Magento 組態檔還原至 `home` 目錄下的 `app/etc/local.xml`

```sh
# 還原 Magento 組態檔
[ -e "./home/app/etc/local.xml" ] || cp local.xml home/app/etc/local.xml
```

## 開發環境調整

> cli 容器預設會以 `www-data` 身份執行指令

```sh
# 設定未加密的基礎網址
docker-compose run --rm cli n98-magerun config:set 'web/unsecure/base_url' 'http://dev.magento.test/'

# 設定加密的基礎網址
docker-compose run --rm cli n98-magerun config:set 'web/secure/base_url' 'https://dev.magento.test/'

# 清空或重設 cookie_domain 及 cookie_path 以避免登入失敗
docker-compose run --rm cli n98-magerun config:set 'web/cookie/cookie_domain' dev.magento.test
docker-compose run --rm cli n98-magerun config:delete 'web/cookie/cookie_path'

# 切換允許開發人員樣版的 "符號連結" 以使用 modman 管理模組
docker-compose run --rm cli n98-magerun config:set 'dev/template/allow_symlink' '1'

# 視需要變更管理者密碼
docker-compose run --rm cli n98-magerun admin:user:change-password

# 視需要停用快取
docker-compose run --rm cli n98-magerun cache:disable
```

## 模組管理

> 以下指令請進入 cli 容器內執行

```sh
# 初始化 modman 配置
modman init

# 確保 ssh id 的權限
chmod 700 ~/.ssh/id_*

# 利用 modman 安裝模組
modman clone git@git.gss.com.tw:magento/magento-translation-zh_TW.git
modman clone git@git.gss.com.tw:magento/magento-provisioning.git
modman clone git@git.gss.com.tw:magento/magento-priceRounding.git
modman clone git@git.gss.com.tw:magento/magento-ezCheckout.git
modman clone git@git.gss.com.tw:magento/magento-extapi2.git
modman clone https://github.com/yireo/Yireo_GoogleTagManager
modman clone git@git.gss.com.tw:magento/magento-enhancedEcommerce.git
modman clone git@git.gss.com.tw:magento/magento-customize-gsscloud.git
modman clone git@git.gss.com.tw:magento/magento-customerNotification.git
modman clone git@git.gss.com.tw:magento/magento-customerApi.git
modman clone git@git.gss.com.tw:magento/magento-affiliateplus-platinum.git
modman clone git@git.gss.com.tw:magento/magento-affiliateApi.git
modman clone git@git.gss.com.tw:magento/magento-affiliateplus-customize.git
modman clone --copy git@git.gss.com.tw:magento/AitCheckoutFields.git
modman clone git@git.gss.com.tw:magento/magento-aitcheckoutfieldsApi2.git
modman clone git@git.gss.com.tw:magento/aitcheckoutfields-customize.git
modman clone git@git.gss.com.tw:magento/Spgateway_MPG_Magento.git
modman clone git@git.gss.com.tw:magento/magento-videgree.git
modman clone git@git.gss.com.tw:magento/BSS_MultiStoreViewPricing.git
modman clone git@git.gss.com.tw:magento/torchbearer.git
modman clone https://github.com/yireo/MageBridgeCore.git
modman clone https://github.com/jacquesbh/jbh_cartmerge.git
modman clone https://github.com/yireo/Yireo_CheckoutTester

# 列出已安裝的 modman 模組
modman list
```
