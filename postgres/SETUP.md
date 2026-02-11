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

1. **Enable recovery mode**: Set `mode: recovery` and uncomment the `recovery` section
2. **Set paths**: Point `recovery.destinationPath` to existing backups (e.g., `s3://bucket/existing-backups`), and `backups.enabled` to `false`
3. **Deploy and wait** for restore to complete
4. **Switch to standalone**: Set `mode: standalone`, comment out `recovery` section, redeploy and set `backups.enabled` to `true`

**Note:** Never delete WALs from the source archive — this breaks recovery.

