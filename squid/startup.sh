#!/bin/bash
set -e

# ensure log directory exists and fixes permission
mkdir -p /var/log/squid 
chmod -R 755 /var/log/squid
chown -R proxy:proxy /var/log/squid

# ensure cache directory exists and fixes permission
mkdir -p /var/spool/squid
chown -R proxy:proxy /var/spool/squid

# make swap dirs
if [ ! -d /var/spool/squid/00 ]; then
  /usr/sbin/squid --foreground -z
fi

# squid runs as proxy user
/usr/sbin/squid --foreground -YC