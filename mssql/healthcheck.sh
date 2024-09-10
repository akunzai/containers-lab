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

if [[ -n "${MSSQL_DATABASE}" ]] && [[ -n "${MSSQL_SA_PASSWORD}" ]]; then
	DBSTATUS=$(sqlcmd -C -h -1 -t 1 -U sa -P "${MSSQL_SA_PASSWORD}" -Q "SET NOCOUNT ON; SELECT state FROM sys.databases WHERE name = N'${MSSQL_DATABASE}'")
else
	DBSTATUS=$(sqlcmd -C -h -1 -t 1 -U sa -P "${MSSQL_SA_PASSWORD}" -Q "SET NOCOUNT ON; SELECT SUM(state) FROM sys.databases")
fi

if [[ -n "${DBSTATUS}" ]]; then
	DBSTATUS=$(echo "${DBSTATUS}" | tr -d '[:space:]')
fi

ERRCODE=$?

echo "db: ${MSSQL_DATABASE}, status: ${DBSTATUS}, error: ${ERRCODE}"

if [[ ${DBSTATUS} -ne 0 ]] || [[ ${ERRCODE} -ne 0 ]]; then
	echo "SQL Server database not ready"
	exit 1
fi
