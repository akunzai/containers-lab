#!/usr/bin/env bash
set -euo pipefail

# This script initializes a read-scale Availability Group (CLUSTER_TYPE = NONE)
# between two SQL Server instances inside the same Podman network.

PRIMARY=${PRIMARY:-mssql1}
SECONDARY=${SECONDARY:-mssql2}
AG_NAME=${AG_NAME:-ag1}
AG_ENDPOINT=${AG_ENDPOINT:-Hadr_endpoint}
MASTER_KEY_PWD=${MASTER_KEY_PWD:-changeit!123}
DB_NAME=${DB_NAME:-ha_sample}

SA_PWD_FILE=/run/secrets/mssql_root.pwd
if [[ ! -f "$SA_PWD_FILE" ]]; then
  echo "ERROR: SA password secret not found at $SA_PWD_FILE" >&2
  exit 1
fi
SA_PWD=$(cat "$SA_PWD_FILE")

sql() {
  local server="$1"; shift
  local query="$1"; shift || true
  /opt/mssql-tools18/bin/sqlcmd -C -S "$server" -U SA -P "$SA_PWD" -b -Q "$query"
}

echo "INFO: Enabling master keys, certificates and endpoints..."

# 1. Create master key, certificate, and endpoint on PRIMARY
sql "$PRIMARY" "
USE master;
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
  CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$MASTER_KEY_PWD';
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'mssql1_cert')
  CREATE CERTIFICATE mssql1_cert WITH SUBJECT = 'mssql1';
IF NOT EXISTS (SELECT * FROM sys.endpoints WHERE name = '$AG_ENDPOINT')
  CREATE ENDPOINT [$AG_ENDPOINT] STATE = STARTED AS TCP (LISTENER_PORT = 5022)
  FOR DATABASE_MIRRORING (ROLE = ALL, AUTHENTICATION = CERTIFICATE mssql1_cert, ENCRYPTION = REQUIRED ALGORITHM AES);
BACKUP CERTIFICATE mssql1_cert TO FILE = '/certs/mssql1_cert.cer';
"

# 2. Create master key, certificate, and endpoint on SECONDARY
sql "$SECONDARY" "
USE master;
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
  CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$MASTER_KEY_PWD';
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'mssql2_cert')
  CREATE CERTIFICATE mssql2_cert WITH SUBJECT = 'mssql2';
IF NOT EXISTS (SELECT * FROM sys.endpoints WHERE name = '$AG_ENDPOINT')
  CREATE ENDPOINT [$AG_ENDPOINT] STATE = STARTED AS TCP (LISTENER_PORT = 5022)
  FOR DATABASE_MIRRORING (ROLE = ALL, AUTHENTICATION = CERTIFICATE mssql2_cert, ENCRYPTION = REQUIRED ALGORITHM AES);
BACKUP CERTIFICATE mssql2_cert TO FILE = '/certs/mssql2_cert.cer';
"

echo "INFO: Exchanging certificates and granting CONNECT on endpoints..."

# 3. Exchange public certificates and grant CONNECT on endpoints
sql "$PRIMARY" "
USE master;
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'mssql2_cert')
  CREATE CERTIFICATE mssql2_cert FROM FILE = '/certs/mssql2_cert.cer';
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'mssql2_login')
  CREATE LOGIN mssql2_login FROM CERTIFICATE mssql2_cert;
GRANT CONNECT ON ENDPOINT::[$AG_ENDPOINT] TO mssql2_login;
"

sql "$SECONDARY" "
USE master;
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'mssql1_cert')
  CREATE CERTIFICATE mssql1_cert FROM FILE = '/certs/mssql1_cert.cer';
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'mssql1_login')
  CREATE LOGIN mssql1_login FROM CERTIFICATE mssql1_cert;
GRANT CONNECT ON ENDPOINT::[$AG_ENDPOINT] TO mssql1_login;
"

echo "INFO: Creating Availability Group ($AG_NAME) with CLUSTER_TYPE = NONE ..."

# 4. Create AG on PRIMARY and join from SECONDARY
sql "$PRIMARY" "
IF NOT EXISTS (SELECT * FROM sys.availability_groups WHERE name = '$AG_NAME')
BEGIN
  CREATE AVAILABILITY GROUP [$AG_NAME]
  WITH (CLUSTER_TYPE = NONE)
  FOR REPLICA ON
    N'mssql1' WITH (
      ENDPOINT_URL = 'TCP://mssql1:5022',
      AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
      FAILOVER_MODE = MANUAL,
      SEEDING_MODE = AUTOMATIC,
      SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
    ),
    N'mssql2' WITH (
      ENDPOINT_URL = 'TCP://mssql2:5022',
      AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
      FAILOVER_MODE = MANUAL,
      SEEDING_MODE = AUTOMATIC,
      SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
    );
END;
ALTER AVAILABILITY GROUP [$AG_NAME] GRANT CREATE ANY DATABASE;
"

sql "$SECONDARY" "
IF NOT EXISTS (SELECT * FROM sys.availability_groups WHERE name = '$AG_NAME')
  ALTER AVAILABILITY GROUP [$AG_NAME] JOIN WITH (CLUSTER_TYPE = NONE);
ALTER AVAILABILITY GROUP [$AG_NAME] GRANT CREATE ANY DATABASE;
"

echo "INFO: Creating sample DB '$DB_NAME' on PRIMARY and adding to AG ..."

# 5. Create sample DB and add to AG with automatic seeding
sql "$PRIMARY" "
IF DB_ID('$DB_NAME') IS NULL
BEGIN
  CREATE DATABASE [$DB_NAME];
  ALTER DATABASE [$DB_NAME] SET RECOVERY FULL;
END;
IF NOT EXISTS (
  SELECT d.name FROM sys.databases d
  JOIN sys.availability_databases_cluster adc ON d.name = adc.database_name
  JOIN sys.availability_groups ag ON ag.group_id = adc.group_id
  WHERE ag.name = '$AG_NAME' AND d.name = '$DB_NAME'
)
  ALTER AVAILABILITY GROUP [$AG_NAME] ADD DATABASE [$DB_NAME];
"

echo "INFO: AG initialization completed. Validate roles with dm_hadr_availability_replica_states."

