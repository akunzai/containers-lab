#!/bin/bash

# setup host alias
hash host >/dev/null 2>&1
if [ "$?" -ne "0" ]; then
    apt-get update -qq >/dev/null 2>&1
    apt-get install --no-install-recommends -yqq dnsutils iproute2
fi
host host.docker.internal >/dev/null 2>&1
if [ "$?" -ne "0" ]; then
    ip route show | awk '/default/ {print $3,"host.docker.internal"}' >> /etc/hosts
fi

if [ -d "$APACHE_DOCUMENT_ROOT" -a "$APACHE_DOCUMENT_ROOT" != "/var/www/html" ]; then
    # link /var/www/html to APACHE_DOCUMENT_ROOT
    rm -rf /var/www/html;
    ln -s $APACHE_DOCUMENT_ROOT /var/www/html;
fi

if [ -e /usr/local/etc/php/conf.d/php.ini ]; then
    # fix: Cannot load Zend OPcache - it was already loaded
    sed -i '/zend_extension=opcache/d' /usr/local/etc/php/conf.d/php.ini
fi

# fix: Require ip not working
if ! grep -q RemoteIPHeader /etc/apache2/apache2.conf; then
    echo -e "RemoteIPHeader X-Forwarded-For\nRemoteIPInternalProxy 172.16.0.0/12" >> /etc/apache2/apache2.conf
fi

if [ -e "$APACHE_DOCUMENT_ROOT/cron.sh" ]; then
    # fix: Permission denied error caused by empty `which php` in cron jobs
    [ -e /usr/bin/php ] || ln -s /usr/local/bin/php /usr/bin/php
    (hash cron && hash gosu ) >/dev/null 2>&1
    if [ "$?" -ne "0" ]; then
        apt-get update -qq >/dev/null 2>&1
        apt-get install --no-install-recommends -yqq cron gosu
    fi
    service cron stauts >/dev/null 2>&1
    if [ "$?" -ne "0" ]; then
        service cron start
    fi
    # only ROOT can write to docker logs
    # /proc/1/fd/1: STDOUT for Docker
    # /proc/1/fd/2: STDERR for Docker
    (
    echo "*/5 * * * * (/usr/sbin/gosu www-data /bin/bash $APACHE_DOCUMENT_ROOT/cron.sh)>/proc/1/fd/1 2>/proc/1/fd/2"
    ) | crontab
fi

apache2-foreground