## Overview

Prometheus, Grafana, and Alertmanager. Grafana is at `grafana.maxstash.io`, backed by SQLite on
its own PVC and signed in through Dex (admin granted by email via `role_attribute_path`).
Retention: 14 days for metrics, 120h for Alertmanager.

## Alert routing

- `Watchdog` → healthchecks.io every 5m — the dead-man's switch; if it stops, monitoring is down.
- `severity: critical` → email; everything → Discord.
- Both muted during the kured window (Tue 02:00–04:00 ET) so weekly reboots don't page.

Config template: [alertmanager.example.yaml](alertmanager.example.yaml).

## Secrets

Three secrets in `monitoring`, sealed into `argocd/secrets/monitoring/` — see
[sealed-secrets/SETUP.md](../sealed-secrets/SETUP.md):

| secret | keys |
| --- | --- |
| `grafana-credentials` | `admin-user`, `admin-password` |
| `grafana-env` | `GF_OAUTH_CLIENT_ID`, `GF_OAUTH_CLIENT_SECRET` |
| `alertmanager` | `alertmanager.yaml` |

## Fire a test alert

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
curl -X POST http://localhost:9093/api/v2/alerts -H 'Content-Type: application/json' -d '[{
  "labels": {"alertname":"TestAlert","severity":"warning","namespace":"monitoring"},
  "annotations": {"summary":"Test alert"},
  "startsAt": "2026-01-12T00:00:00Z", "endsAt": "2026-01-12T23:59:59Z"
}]'
```
