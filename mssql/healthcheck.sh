#!/bin/bash

set -e

# sqlcmd location changed since SQL Server 2022 (16.x) CU 14
# https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker
if [[ -d "/opt/mssql-tools18/bin" ]]; then
	PATH="/opt/mssql-tools18/bin:${PATH}"
elif [[ -d "/opt/mssql-tools/bin" ]]; then
	PATH="/opt/mssql-tools/bin:${PATH}"
fi

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [[ -n "${!var:-}" ]] && [[ -n "${!fileVar:-}" ]]; then
		mysql_error "Both ${var} and ${fileVar} are set (but are exclusive)"
	fi
	local val="${def}"
	if [[ -n "${!var:-}" ]]; then
		val="${!var}"
	elif [[ -n "${!fileVar:-}" ]]; then
		val="$(<"${!fileVar}")"
	fi
	export "${var}"="${val}"
	unset "${fileVar}"
}

file_env 'MSSQL_SA_PASSWORD'

DBSTATUS=1
ERRCODE=1

if [[ -z "${MSSQL_SA_PASSWORD:-}" ]]; then
	echo "ERROR: MSSQL_SA_PASSWORD is not set. Exiting..." >&2
	exit 1
fi

if [[ -z "${MSSQL_DATABASE:-}" ]] || [[ "${MSSQL_DATABASE}" == *'$'* ]]; then
	DBSTATUS=$(sqlcmd -C -h -1 -t 1 -U sa -P "${MSSQL_SA_PASSWORD}" -Q "SET NOCOUNT ON; SELECT SUM(state) FROM sys.databases")
else
	DBSTATUS=$(sqlcmd -C -h -1 -t 1 -U sa -P "${MSSQL_SA_PASSWORD}" -Q "SET NOCOUNT ON; SELECT state FROM sys.databases WHERE name = N'${MSSQL_DATABASE}'")
fi

if [[ -n "${DBSTATUS}" ]]; then
	DBSTATUS=$(echo "${DBSTATUS}" | tr -d '[:space:]')
fi

ERRCODE=$?

if [[ ${DBSTATUS} -ne 0 ]] || [[ ${ERRCODE} -ne 0 ]]; then
	if [[ -z "${MSSQL_DATABASE:-}" ]] || [[ "${MSSQL_DATABASE}" == *'$'* ]]; then
		echo "ERROR: All databases are not ready (status:${DBSTATUS}, errcode:${ERRCODE})" >&2
	else
		echo "ERROR: ${MSSQL_DATABASE} database is not ready (status:${DBSTATUS}, errcode:${ERRCODE})" >&2
	fi
	exit 1
else
	if [[ -z "${MSSQL_DATABASE:-}" ]] || [[ "${MSSQL_DATABASE}" == *'$'* ]]; then
		echo "INFO: All databases are ready" >&2
	else
		echo "INFO: ${MSSQL_DATABASE} database is ready" >&2
	fi
	exit 0
fi
