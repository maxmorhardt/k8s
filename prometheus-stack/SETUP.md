## Overview

Prometheus, Grafana, and Alertmanager. Grafana is at `grafana.maxstash.io`, backed by
Postgres and signed in through Dex.

## Alert routing

- `Watchdog` → healthchecks.io every 5m - the dead-man's switch. If it stops, monitoring
  itself is down.
- `severity: critical` → email, and everything → Discord.
- Both are muted during the kured maintenance window, Tuesday 02:00–04:00 ET, so weekly
  reboots do not page.

Config template: [alertmanager.example.yaml](alertmanager.example.yaml).

## Secrets

Three secrets in `monitoring`, sealed into `argocd/secrets/monitoring/` — see
[sealed-secrets/SETUP.md](../sealed-secrets/SETUP.md):

| secret | keys |
| --- | --- |
| `grafana-credentials` | `admin-user`, `admin-password` |
| `grafana-env` | `GF_DB_HOST`, `GF_DB_NAME`, `GF_DB_USER`, `GF_DB_PASSWORD`, `GF_OAUTH_CLIENT_ID`, `GF_OAUTH_CLIENT_SECRET` |
| `alertmanager` | `alertmanager.yaml` |

## Commands

```bash
kubectl get prometheusrules -n monitoring -o yaml
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093

# fire a test alert at a running port-forward
curl -X POST http://localhost:9093/api/v2/alerts -H 'Content-Type: application/json' -d '[{
  "labels": {"alertname":"TestAlert","severity":"warning","namespace":"monitoring"},
  "annotations": {"summary":"Test alert"},
  "startsAt": "2026-01-12T00:00:00Z", "endsAt": "2026-01-12T23:59:59Z"
}]'
```

## Notes

- Retention: 14 days for Prometheus metrics, 120 hours for Alertmanager.
- Depends on Postgres (Grafana database), Dex (`grafana` static client, admin granted by
  email via `role_attribute_path`), and the `maxstash` Gateway for the HTTPRoute.
