#!/bin/env bash
set -e

if [[ "$1" == '/usr/sbin/nrpe' ]]; then

	[[ -e /var/run/nagios/nrpe.pid ]] && rm /var/run/nagios/nrpe.pid

	"$@"

	# keep the container running
	tail -f /var/log/nrpe.log
fi

exec "$@"
