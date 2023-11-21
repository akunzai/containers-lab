#!/bin/env bash

# fix: Require ip not working
if ! grep -q RemoteIPHeader /etc/apache2/apache2.conf; then
    echo -e "RemoteIPHeader X-Forwarded-For\nRemoteIPInternalProxy 172.16.0.0/12" >>/etc/apache2/apache2.conf
fi

if [ -d "$APACHE_DOCUMENT_ROOT" -a "$APACHE_DOCUMENT_ROOT" != "/var/www/html" ]; then
    # link /var/www/html to APACHE_DOCUMENT_ROOT
    rm -rf /var/www/html
    ln -s $APACHE_DOCUMENT_ROOT /var/www/html
    # make sure permission
    chown -R www-data:www-data $APACHE_DOCUMENT_ROOT &
fi

if [ -n "$CRON" ] && [ "$CRON" -eq "1" ]; then
    # install tools
    hash gosu >/dev/null 2>&1
    if [ "$?" -ne "0" ]; then
        apt-get update -qq >/dev/null
        apt-get install --no-install-recommends -yqq cron gosu >/dev/null
    fi
    # fix: Permission denied error caused by empty `which php` in cron jobs
    [ -e /usr/bin/php ] || ln -s /usr/local/bin/php /usr/bin/php
    service cron stauts >/dev/null 2>&1
    if [ "$?" -ne "0" ]; then
        service cron start
    fi
    # only ROOT can write to docker logs
    # /proc/1/fd/1: STDOUT for Docker
    # /proc/1/fd/2: STDERR for Docker
    (
        [ -e "$APACHE_DOCUMENT_ROOT/cron.sh" ] && echo "*/5 * * * * (/usr/sbin/gosu www-data /bin/bash $APACHE_DOCUMENT_ROOT/cron.sh)>/proc/1/fd/1 2>/proc/1/fd/2"
    ) | crontab
fi

apache2-foreground
