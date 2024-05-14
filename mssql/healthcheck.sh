#!/bin/bash

DBSTATUS=1
ERRCODE=1

if [ -n "$MSSQL_DATABASE" ]; then
	DBSTATUS=$(/opt/mssql-tools/bin/sqlcmd -h -1 -t 1 -U sa -P $MSSQL_SA_PASSWORD -Q "SET NOCOUNT ON; Select state from sys.databases WHERE name = N'$MSSQL_DATABASE'")
else
	DBSTATUS=$(/opt/mssql-tools/bin/sqlcmd -h -1 -t 1 -U sa -P $MSSQL_SA_PASSWORD -Q "SET NOCOUNT ON; Select SUM(state) from sys.databases")
fi

ERRCODE=$?

if [[ $DBSTATUS -ne 0 ]] || [[ $ERRCODE -ne 0 ]]; then
	echo "SQL Server database not ready"
	exit 1
fi