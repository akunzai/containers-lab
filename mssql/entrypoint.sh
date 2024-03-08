#!/bin/bash

# Run the script to set up the DB in the background
/setup.sh &

# Start SQL Server
/opt/mssql/bin/sqlservr