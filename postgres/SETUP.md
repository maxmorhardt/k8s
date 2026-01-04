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
  username: <base64-encoded-username>
  password: <base64-encoded-password>
```

Create the `aws-s3-credentials` secret for backups:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: aws-s3-credentials
  namespace: db
type: Opaque
data:
  AWS_ACCESS_KEY_ID: <base64-encoded-access-key>
  AWS_SECRET_ACCESS_KEY: <base64-encoded-secret-key>
  AWS_REGION: <base64-encoded-region>
```

## Storage

Ensure the storage class `postgres` is available for persistent volumes.

## Configuration

Update `cluster.yaml`:
1. Set the correct S3 bucket name in the backup configuration
2. Adjust PostgreSQL parameters if needed
3. Verify resource limits match your cluster capacity

## Connection Information

After deployment, the cluster will be available at:
- **Primary (read-write):** `postgres-rw.db.svc.cluster.local:5432`
- **Read-only replicas:** `postgres-ro.db.svc.cluster.local:5432`
- **Any replica (read):** `postgres-r.db.svc.cluster.local:5432`

## Migration from Bitnami

1. Backup existing database:
   ```bash
   kubectl exec -n db deployment/db-postgresql -- pg_dumpall -U postgres > backup.sql
   ```

2. Deploy CloudNativePG cluster (will start fresh)

3. Restore data:
   ```bash
   kubectl exec -n db postgres-1 -- psql -U maxmorhardt -d authentik < backup.sql
   ```

## Monitoring

Check cluster status:
```bash
kubectl get cluster -n db
kubectl cnpg status postgres -n db
```

View backup status:
```bash
kubectl get backup -n db
```
