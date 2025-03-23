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
wait_for_startup() {
	local timeout="${1:-60}"
	local delay="${2:-1}"
	local dbstatus=1
	local errcode=1
	local start_time=$(date +%s)
	local end_time=$((start_time + timeout))

	if [[ -z "${MSSQL_SA_PASSWORD:-}" ]]; then
		echo "ERROR: MSSQL_SA_PASSWORD is not set. Exiting..." >&2
		exit 1
	fi

	local iteration=0
	while [[ $(date +%s) -lt ${end_time} ]] && [[ ${dbstatus} -ne 0 || ${errcode} -ne 0 ]]; do
		iteration=$((iteration + 1))
		dbstatus=$(sqlcmd -C -h -1 -t 1 -U sa -P "${MSSQL_SA_PASSWORD}" -Q "SET NOCOUNT ON; SELECT SUM(state) FROM sys.databases" 2>/dev/null)
		errcode=$?

		if [[ -n "${dbstatus}" ]]; then
			dbstatus=$(echo "${dbstatus}" | tr -d '[:space:]')
		fi

		local elapsed=$(($(date +%s) - start_time))
		local remaining=$((timeout - elapsed))
		echo "INFO: Waiting for SQL Server to start up ... iteration:${iteration}, elapsed:${elapsed}s, remaining:${remaining}s, status:${dbstatus}, errcode:${errcode}" >&2
		sleep "${delay}"
	done

	local total_elapsed=$(($(date +%s) - start_time))
	if [[ ${dbstatus} -ne 0 ]] || [[ ${errcode} -ne 0 ]]; then
		echo "WARN: SQL Server failed to start up after ${total_elapsed}s, status:${dbstatus}, errcode:${errcode}, timeout:${timeout}" >&2
		exit 1
	fi
}

create_db() {
	if [[ -z "${MSSQL_DATABASE:-}" ]] || [[ "${MSSQL_DATABASE}" == *'$'* ]]; then
		return
	fi
	echo "INFO: Creating database ${MSSQL_DATABASE} ..." >&2
	sqlcmd -C -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -Q "CREATE DATABASE ${MSSQL_DATABASE}"
}

create_user() {
	if [[ -z "${MSSQL_USER}" ]] || [[ -z "${MSSQL_PASSWORD}" ]]; then
		return
	fi
	echo "INFO: Creating user ${MSSQL_USER} ..." >&2
	sqlcmd -C -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -Q "CREATE LOGIN ${MSSQL_USER} WITH PASSWORD = '${MSSQL_PASSWORD}'"
}

grant_user_as_db_owner() {
	if [[ -z "${MSSQL_DATABASE:-}" ]] || [[ -z "${MSSQL_USER}" ]]; then
		return
	fi
	echo "INFO: Granting user [${MSSQL_USER}] as db [${MSSQL_DATABASE}] owner ..." >&2
	sqlcmd -C -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -Q "Use [${MSSQL_DATABASE}]; CREATE USER [${MSSQL_USER}] FROM LOGIN [${MSSQL_USER}]; EXEC sp_addrolemember 'db_owner', '${MSSQL_USER}'"
}

run_init_script() {
	if [[ -z "${MSSQL_INIT_SCRIPT}" ]] || [[ ! -f "${MSSQL_INIT_SCRIPT}" ]]; then
		return
	fi
	echo "INFO: Initializing database with ${MSSQL_INIT_SCRIPT} ..." >&2
	if [[ -x "${MSSQL_INIT_SCRIPT}" ]]; then
		"${MSSQL_INIT_SCRIPT}"
	else
		sqlcmd -C -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -i "${MSSQL_INIT_SCRIPT}"
	fi
}

file_env 'MSSQL_SA_PASSWORD'
file_env 'MSSQL_PASSWORD'

if [[ "$1" == '/opt/mssql/bin/sqlservr' ]]; then
	function initialize_app_database() {
		# Wait for SQL Server to start up
		wait_for_startup "${MSSQL_STARTUP_TIMEOUT:-60}" "${MSSQL_STARTUP_DELAY:-1}"
		if [[ -x "${MSSQL_INIT_SCRIPT}" ]]; then
			run_init_script
		else
			# Creates a custom database and user if specified
			create_db
			create_user
			grant_user_as_db_owner
			run_init_script
		fi
	}
	initialize_app_database &
fi

exec "$@"
