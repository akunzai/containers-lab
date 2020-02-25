#!/bin/sh
apt-get update -qq && \
apt-get install --no-install-recommends -yqq cron gosu && \
service cron start

( crontab -l 2>/dev/null; \
# only ROOT can write to docker logs
# /proc/1/fd/1: STDOUT for Docker
# /proc/1/fd/2: STDERR for Docker
echo "* * * * * [[ -x /var/www/html/cron.sh ]] && /usr/sbin/gosu www-data /var/www/html/cron.sh >/proc/1/fd/1 2>/proc/1/fd/2";
) | crontab