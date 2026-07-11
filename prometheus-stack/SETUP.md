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
```

## Alertmanager Config

Fill in `alertmanager.yaml` with real values before creating the secret:
- `smtp_auth_password`
- `healthchecks-io` ping URL (`hc-ping.com/<uuid>`)
- `discord-webhook` URL

```yaml
global:
  resolve_timeout: 5m
  smtp_from: no-reply@maxstash.io
  smtp_smarthost: smtp.zoho.com:587
  smtp_auth_username: no-reply@maxstash.io
  smtp_auth_password: <smtp-password>
  smtp_require_tls: true

inhibit_rules:
  - source_matchers:
      - 'severity = critical'
    target_matchers:
      - 'severity =~ warning|info'
    equal:
      - namespace
      - alertname
  - source_matchers:
      - 'severity = warning'
    target_matchers:
      - 'severity = info'
    equal:
      - namespace
      - alertname
  - source_matchers:
      - 'alertname = InfoInhibitor'
    target_matchers:
      - 'severity = info'
    equal:
      - namespace
  - target_matchers:
      - 'alertname = InfoInhibitor'

time_intervals:
  - name: maintenance-window
    time_intervals:
      - weekdays: [tuesday]
        times:
          - start_time: '02:00'
            end_time: '04:00'
        location: America/New_York

route:
  group_by: [namespace]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'null'
  routes:
    - match:
        alertname: Watchdog
      receiver: healthchecks-io
      repeat_interval: 5m
    - match:
        alertname: InfoInhibitor
      receiver: 'null'
    - match:
        severity: critical
      receiver: email-receiver
      continue: true
      mute_time_intervals:
        - maintenance-window
    - receiver: discord-receiver
      continue: true
      mute_time_intervals:
        - maintenance-window

receivers:
  - name: 'null'
  - name: healthchecks-io
    webhook_configs:
      - url: https://hc-ping.com/<uuid>
        send_resolved: false
  - name: email-receiver
    email_configs:
      - to: max@maxstash.io
        send_resolved: false
  - name: discord-receiver
    discord_configs:
      - webhook_url: <discord-webhook>
        username: Alerts
        send_resolved: true

templates:
  - /etc/alertmanager/config/*.tmpl
```

Then create the secret:

```bash
kubectl create secret generic alertmanager \
  --from-file=alertmanager.yaml=prometheus-stack/alertmanager.yaml \
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
- Dex OIDC provider at login.maxstash.io (`grafana` static client; admin granted by email via `role_attribute_path`)
- Envoy Gateway (`maxstash` Gateway) for the grafana.maxstash.io HTTPRoute

## Notes
- Default retention is 14 days for Prometheus metrics
- Alertmanager retention is 120 hours