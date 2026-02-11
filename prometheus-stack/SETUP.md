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

kubectl create secret generic alertmanager \
  --from-literal=smtp-password='<smtp-password>' \
	--from-literal=discord-webhook='<discord-webhook-url>' \
  -n monitoring
```

## Commands
```bash
# See status of deployment
kubectl get alertmanager -n monitoring kube-prometheus-stack-alertmanager -o yaml | grep -A 20 status

# Alert rules
kubectl get prometheusrules -n monitoring -o yaml

# Port forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093

# Make alert
curl -X POST http://localhost:9093/api/v2/alerts -H "Content-Type: application/json" -d '[
  {
    "labels": {
      "alertname": "TestAlert",
      "severity": "warning",
      "namespace": "monitoring"
    },
    "annotations": {
      "summary": "Test email alert",
      "description": "Testing SMTP email notifications"
    },
    "startsAt": "2026-01-12T00:00:00Z",
    "endsAt": "2026-01-12T23:59:59Z"
  }
]'
```

## Dependencies
- PostgreSQL database for Grafana
- Authentik OIDC provider at login.maxstash.io (user with `grafana-admin` group)

## Notes
- Default retention is 14 days for Prometheus metrics
- Alertmanager retention is 120 hours