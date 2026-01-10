## Secrets Required

Create the `grafana-credentials` secret for admin access:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-credentials
  namespace: monitoring
type: Opaque
stringData:
  admin-user: <admin-username>
  admin-password: <admin-password>
```

Create the `grafana-env` secret for environment variables:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-env
  namespace: monitoring
type: Opaque
stringData:
  GRAFANA_CLIENT_ID: <authentik-client-id>
  GRAFANA_CLIENT_SECRET: <authentik-client-secret>
  GRAFANA_DATABASE_PASSWORD: <postgres-password>
```

## Database Setup

Create the Grafana database and user in PostgreSQL:

```sql
CREATE USER grafana WITH PASSWORD '<postgres-password>';
CREATE DATABASE grafana OWNER grafana;
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