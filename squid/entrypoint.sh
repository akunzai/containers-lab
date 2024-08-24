#!/bin/bash
set -e

if [ "$1" == '/usr/sbin/squid' ]; then

  # make swap dirs
  if [ ! -d /var/spool/squid/00 ]; then
    /usr/sbin/squid --foreground -z
  fi

fi

exec "$@"
