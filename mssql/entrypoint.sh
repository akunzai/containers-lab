#!/bin/bash

set -e

# sqlcmd location changed since SQL Server 2022 (16.x) CU 14
# https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker
if [[ -d "/opt/mssql-tools18/bin" ]]; then
	export PATH="/opt/mssql-tools18/bin:${PATH}"
elif [[ -d "/opt/mssql-tools/bin" ]]; then
	export PATH="/opt/mssql-tools/bin:${PATH}"
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
		echo "Both ${var} and ${fileVar} are set (but are exclusive)" >&2
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

# Wait for SQL Server to start up by ensuring that
# calling SQLCMD does not return an error code, which will ensure that sqlcmd is accessible
# and that system and user databases return "0" which means all databases are in an "online" state
# https://docs.microsoft.com/sql/relational-databases/system-catalog-views/sys-databases-transact-sql
wait_for_sql_server() {
	local timeout="${1:-60}"
	local delay="${2:-1}"
	local dbstatus=1
	local errcode=1
	local i=0

	if [[ -z "${MSSQL_SA_PASSWORD}" ]]; then
		echo "MSSQL_SA_PASSWORD is not set. Exiting..."
		exit 1
	fi

	while [[ ${dbstatus} -ne 0 ]] && [[ ${i} -lt ${timeout} ]] && [[ ${errcode} -ne 0 ]]; do
		i=$((i + 1))
		dbstatus="$(sqlcmd -h -1 -t 1 -U sa -P "${MSSQL_SA_PASSWORD}" -Q "SET NOCOUNT ON; SELECT SUM(state) FROM sys.databases")"
		if [[ -n "${dbstatus}" ]]; then
			dbstatus="$(echo "${dbstatus}" | tr -d '[:space:]')"
		fi
		errcode=$?
		sleep "${delay}"
	done

	if [[ ${dbstatus} -ne 0 ]] || [[ ${errcode} -ne 0 ]]; then
		echo "SQL Server took more than ${timeout} seconds to start up or one or more databases are not in an ONLINE state"
		exit 1
	fi
}

create_db_and_user() {
	if [[ -z "${MSSQL_DATABASE}" ]]; then
		return
	fi
	echo "> Creating database ${MSSQL_DATABASE} ..."
	sqlcmd -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -Q "CREATE DATABASE ${MSSQL_DATABASE}"
	if [[ -z "${MSSQL_USER}" ]] || [[ -z "${MSSQL_PASSWORD}" ]]; then
		return
	fi
	echo "> Creating user ${MSSQL_USER} ..."
	sqlcmd -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -Q "CREATE LOGIN ${MSSQL_USER} WITH PASSWORD = '${MSSQL_PASSWORD}'"
	echo "> Granting user [${MSSQL_USER}] as db [${MSSQL_DATABASE}] owner ..."
	sqlcmd -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -Q "Use [${MSSQL_DATABASE}]; CREATE USER [${MSSQL_USER}] FROM LOGIN [${MSSQL_USER}]; EXEC sp_addrolemember 'db_owner', '${MSSQL_USER}'"
}

import_sql_file() {
	if [[ -z "${MSSQL_INIT_SCRIPT}" ]] || [[ ! -f "${MSSQL_INIT_SCRIPT}" ]]; then
		return
	fi
	echo "Initializing database with ${MSSQL_INIT_SCRIPT} ..."
	sqlcmd -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -i "${MSSQL_INIT_SCRIPT}"
}

file_env 'MSSQL_SA_PASSWORD'
file_env 'MSSQL_PASSWORD'

if [[ "$1" == '/opt/mssql/bin/sqlservr' ]]; then
	function initialize_app_database() {
		# Wait for SQL Server to start up
		wait_for_sql_server 100
		# Creates a custom database and user if specified
		create_db_and_user
		import_sql_file
	}
	initialize_app_database &
fi

exec "$@"
