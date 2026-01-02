## Secrets Required

Create the `grafana-credentials` secret manually before deployment:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-credentials
  namespace: monitoring
type: Opaque
data:
  admin-user: <base64-encoded-admin-username>
  admin-password: <base64-encoded-admin-password>
  client-id: <base64-encoded-authentik-client-id>
  client-secret: <base64-encoded-authentik-client-secret>
```

## Storage
1. SSH into node that will host Grafana (max-worker)
2. Create directory /data/grafana with 1000:1000 owner/group
   ```bash
   sudo mkdir -p /data/grafana
   sudo chown -R 1000:1000 /data/grafana
   ```

## OIDC

### In Authentik:
1. Create an OAuth2/OIDC Provider for Grafana
   - Redirect URIs: `https://grafana.maxstash.io/login/generic_oauth`

2. Create an Application linked to the provider
   - Name: Grafana
   - Slug: grafana
   - Copy the Client ID and Client Secret

3. Create a group for Grafana admins (grafana-admin)