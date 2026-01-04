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
  AWS_ACCESS_KEY_ID: <your-access-key>
  AWS_SECRET_ACCESS_KEY: <your-secret-key>
  AWS_REGION: <your-region>
```

## Storage Setup

Create `/data/postgresql` directories on each worker node with correct permissions:

```bash
# On each worker node
mkdir -p /data/postgresql
chown 26:26 /data/postgresql
chmod 700 /data/postgresql
```
