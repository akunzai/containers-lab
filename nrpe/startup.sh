#!/bin/bash
set -e

# setup allowed hosts
if [ -n "$ALLOWED_HOSTS" ]; then
 sed -i "s|allowed_hosts=.*|allowed_hosts=$ALLOWED_HOSTS|" /etc/nagios/nrpe.cfg
fi

# ensure pid directory exists and fixes permission
mkdir -p /var/run/nagios
chown -R nagios:nagios /var/run/nagios
[ -e /var/run/nagios/nrpe.pid ] && rm /var/run/nagios/nrpe.pid

# ensure log directory exists and fixes permission
touch /var/log/nrpe.log
chown nagios:nagios /var/log/nrpe.log

# start nrpe daemon with the least privileges
gosu nagios /usr/sbin/nrpe -c /etc/nagios/nrpe.cfg -d

# keep the container running
tail -f /var/log/nrpe.log