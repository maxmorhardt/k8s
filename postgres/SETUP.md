## Secrets Required

Create the `postgres-credentials` secret manually before deployment:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
  namespace: maxstash-global
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

## Notes
- Port 5432 is exposed via NodePort on the host node
- Create databases for applications (keycloak, etc.)