## Secrets

```bash
kubectl create secret generic grafana-credentials \
  --from-literal=admin-user=<user> \
  --from-literal=admin-password=<password> \
  -n monitoring

kubectl create secret generic grafana-env \
  --from-literal=GF_DB_HOST=<postgres-host> \
  --from-literal=GF_DB_NAME=<postgres-db-name> \
  --from-literal=GF_DB_USER=<postgres-user> \
  --from-literal=GF_DB_PASSWORD=<postgres-password> \
  --from-literal=GF_OAUTH_CLIENT_ID=<client-id> \
  --from-literal=GF_OAUTH_CLIENT_SECRET=<client-secret> \
  -n monitoring

kubectl create secret generic alertmanager-smtp \
  --from-literal=smtp_smarthost='smtp.gmail.com:587' \
  --from-literal=smtp_auth_username='alerts@maxstash.io' \
  --from-literal=smtp_auth_password='<app-password>' \
  -n monitoring
```

## Dependencies
- PostgreSQL database for Grafana
- Authentik OIDC provider at login.maxstash.io (users in `grafana-admin` group get Admin role)
- Longhorn storage class
- TLS cert: maxstash.io-tls

## Notes
- Default retention is 14 days for Prometheus metrics
- Alertmanager retention is 120 hours