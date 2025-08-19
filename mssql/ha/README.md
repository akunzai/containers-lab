# SQL Server HA (Read-Scale AG) with Podman Compose

This example sets up a read-scale Availability Group (cluster_type = NONE) across two SQL Server 2022 containers on the same host network, plus an optional HAProxy TCP frontend.

Notes and limitations:
- No cluster manager (Pacemaker) – manual failover only. Listener is not supported with `CLUSTER_TYPE = NONE`.
- Automatic seeding is enabled. Secondary will be seeded when databases are added to the AG.
- This is for development/demo. For production, use multiple hosts and a supported cluster manager (Pacemaker) or Kubernetes operator.

## Topology
- `mssql1`: primary replica candidate (port 14331 on host)
- `mssql2`: secondary replica candidate (port 14332 on host)
- `ag-setup`: one-shot initializer that configures certificates, endpoints, AG, and adds a sample DB
- `haproxy` (optional): exposes a single local port 1433 and forwards to the first healthy server (simple failover; does not detect AG role)

## Prerequisites
- Podman >= 4.8.0 and Podman Compose >= 1.2.0
- Secrets created for SA password:
  ```sh
  openssl rand -base64 16 | podman secret create --replace mssql_root.pwd -
  ```
- Build base image in `mssql/` first (used by all services here):
  ```sh
  cd mssql
  podman-compose build
  ```

## Bring up the HA stack
```sh
cd mssql/ha
podman-compose -f compose.ha.yml up -d mssql1 mssql2

# Wait until both replicas are healthy, then run AG initializer
podman-compose -f compose.ha.yml up --no-deps ag-setup

# (Optional) Start HAProxy frontend on localhost:1433
podman-compose -f compose.ha.yml up -d haproxy
```

## Verify AG and roles
```sh
# Check primary/secondary role
podman exec -it mssql1 /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U SA -P $(cat /run/secrets/mssql_root.pwd) \
  -Q "SELECT r.replica_server_name, rs.role_desc FROM sys.availability_replicas r JOIN sys.dm_hadr_availability_replica_states rs ON r.replica_id = rs.replica_id;"

# Check databases in AG
podman exec -it mssql1 /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U SA -P $(cat /run/secrets/mssql_root.pwd) \
  -Q "SELECT ag.name AS ag_name, adc.database_name FROM sys.availability_groups ag JOIN sys.availability_databases_cluster adc ON ag.group_id = adc.group_id;"
```

## Connect
- Direct to primary (initially `mssql1`): `localhost,14331`
- Direct to secondary: `localhost,14332`
- Via HAProxy (simple TCP failover): `localhost,1433` (primary preferred)

Add `TrustServerCertificate=true` in connection strings or use `sqlcmd -C`.

## Add your own database to the AG
```sh
# On primary (mssql1): create DB and add to AG
podman exec -it mssql1 /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U SA -P $(cat /run/secrets/mssql_root.pwd) -Q "
CREATE DATABASE [mydb];
ALTER DATABASE [mydb] SET RECOVERY FULL;
ALTER AVAILABILITY GROUP [ag1] ADD DATABASE [mydb];
"
```

## Manual failover
```sh
# Manually fail over from current primary to secondary
podman exec -it mssql1 /opt/mssql-tools18/bin/sqlcmd -C -S mssql1 -U SA -P $(cat /run/secrets/mssql_root.pwd) -Q "
ALTER AVAILABILITY GROUP [ag1] FAILOVER;
"

# If using HAProxy, it switches only when the old primary is down.
# For role-aware routing, integrate an app-side check or a custom health script.
```

## Customization
- Override via environment on `ag-setup`: `AG_NAME`, `AG_ENDPOINT`, `PRIMARY`, `SECONDARY`, `MASTER_KEY_PWD`, `DB_NAME`.
- Certificates are exchanged through a named volume `ag_certs` mounted at `/certs`.

## Cleanup
```sh
podman-compose -f compose.ha.yml down -v
```

