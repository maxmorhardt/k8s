## Secrets Required

Create the `postgres-superuser` secret for the postgres superuser:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-superuser
  namespace: cnpg-database
type: Opaque
stringData:
  username: postgres
  password: <your-superuser-password>
```

Create the `postgres-admin-user` secret for the database owner:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-admin-user
  namespace: cnpg-database
type: Opaque
stringData:
  username: <your-admin-username>
  password: <your-admin-password>
```

Create the `aws-s3-credentials` secret for backups:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: aws-s3-credentials
  namespace: cnpg-database
type: Opaque
stringData:
  ACCESS_KEY_ID: <your-access-key>
  ACCESS_SECRET_KEY: <your-secret-key>
```

## Recovery

1. Run the **PostgreSQL Cluster CD** workflow with mode set to `recovery`
2. Wait for all 3 instances to become ready
3. Run the workflow again with mode set to `normal` to switch to standalone with backups enabled

**Note:** Never delete WALs from the source archive — this breaks recovery.

