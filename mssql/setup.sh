#!/bin/bash

# Wait 60 seconds for SQL Server to start up by ensuring that 
# calling SQLCMD does not return an error code, which will ensure that sqlcmd is accessible
# and that system and user databases return "0" which means all databases are in an "online" state
# https://docs.microsoft.com/sql/relational-databases/system-catalog-views/sys-databases-transact-sql
DBSTATUS=1
ERRCODE=1
i=0

while [[ $DBSTATUS -ne 0 ]] && [[ $i -lt 60 ]] && [[ $ERRCODE -ne 0 ]]; do
	i=$i+1
	DBSTATUS=$(/opt/mssql-tools/bin/sqlcmd -h -1 -t 1 -U sa -P $MSSQL_SA_PASSWORD -Q "SET NOCOUNT ON; Select SUM(state) from sys.databases")
	ERRCODE=$?
	sleep 1
done

if [[ $DBSTATUS -ne 0 ]] || [[ $ERRCODE -ne 0 ]]; then
	echo "SQL Server took more than 60 seconds to start up or one or more databases are not in an ONLINE state"
	exit 1
fi

# Creates a custom database and user if specified
if  [ -n "$MSSQL_DATABASE" ]; then
	echo "Creating database $MSSQL_DATABASE ..."
	/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -Q "Use [master]; CREATE DATABASE $MSSQL_DATABASE"
	if  [ -n "$MSSQL_USER" ] && [ -n "$MSSQL_PASSWORD" ]; then
		echo "Creating user $MSSQL_USER ..."
		/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -Q "Use [master]; CREATE LOGIN $MSSQL_USER WITH PASSWORD = '$MSSQL_PASSWORD'"
		echo "Granting user [$MSSQL_USER] as db [$MSSQL_DATABASE] owner ..."
		/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -Q "Use [$MSSQL_DATABASE]; CREATE USER [$MSSQL_USER] FROM LOGIN [$MSSQL_USER]; EXEC sp_addrolemember 'db_owner', '$MSSQL_USER'"
	fi
fi

if [ -n "$MSSQL_INIT_SCRIPT" ] && [ -f "$MSSQL_INIT_SCRIPT" ]; then
	echo "Initializing database with $MSSQL_INIT_SCRIPT ..."
	/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -d $MSSQL_DATABASE -i $MSSQL_INIT_SCRIPT
fi