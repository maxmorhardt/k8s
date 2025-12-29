## Secrets Required

Create the `grafana-credentials` secret manually before deployment:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-credentials
  namespace: maxstash-global
type: Opaque
data:
  admin-user: <base64-encoded-admin-username>
  admin-password: <base64-encoded-admin-password>
  client-id: <base64-encoded-keycloak-client-id>
  client-secret: <base64-encoded-keycloak-client-secret>
```

## Storage
1. SSH into node that will host Grafana (max-worker)
2. Create directory /data/grafana with 1000:1000 owner/group
   ```bash
   sudo mkdir -p /data/grafana
   sudo chown -R 1000:1000 /data/grafana
   ```

## OIDC

### In Keycloak:
1. Create Client in Keycloak realm for Grafana
   - Client Authentication must be true to obtain client secret
   - Redirect urls and post logout urls should include https://<dns> and https://<dns>/*
   - Standard flow and Direct Access Grants should be true
   - Configure grafana-dedicated scope with Group Membership for claim name 'groups'
   - More details: https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/keycloak/

2. Create group for Grafana Admin