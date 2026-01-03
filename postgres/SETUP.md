## Secrets Required

Create the `postgres-credentials` secret manually before deployment:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
  namespace: db
type: Opaque
data:
  admin-password: <base64-encoded-admin-password>
  user-password: <base64-encoded-user-password>
```

## Storage
1. SSH into node that will host Postgres (max-worker)
2. Create directory /bitnami/postgresql with 1001:1001 owner/group
   ```bash
   sudo mkdir -p /bitnami/postgresql
   sudo chown -R 1001:1001 /bitnami/postgresql
   ```
3. Ensure drive has at least 256Gi available

## User Permissions

Grant monitoring privileges to the application user:

```sql
-- Connect as postgres admin
psql -h localhost -p 5432 -U postgres -d postgres

-- Grant pg_monitor role for monitoring functions
GRANT pg_monitor TO <user>;
```

The `pg_monitor` role provides access to:
- `pg_ls_waldir()` - WAL directory listing
- `pg_ls_logdir()` - Log directory listing
- Statistics and monitoring views