#!/bin/sh

grep free.nchc.org.tw /etc/apt/sources.list >/dev/null || sed -i 's,^\deb http://deb.debian.org,deb https://free.nchc.org.tw,g' /etc/apt/sources.list

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
echo "* * * * * [[ -x /home/site/wwwroot/cron.sh ]] && /usr/sbin/gosu www-data /home/site/wwwroot/cron.sh >/home/logs/cron.log 2>&1";
) | crontab