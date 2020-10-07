#!/bin/sh
# preferred mirror site
grep free.nchc.org.tw /etc/apt/sources.list >/dev/null || sed -i 's,^\deb http://deb.debian.org,deb https://free.nchc.org.tw,g' /etc/apt/sources.list
# fix: Cannot load Zend OPcache - it was already loaded
sed -i '/zend_extension=opcache/d' /usr/local/etc/php/conf.d/php.ini
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
echo "* * * * * [ -x /home/site/wwwroot/cron.sh ] && (/usr/sbin/gosu www-data /home/site/wwwroot/cron.sh)>/proc/1/fd/1 2>/proc/1/fd/2"
) | crontab