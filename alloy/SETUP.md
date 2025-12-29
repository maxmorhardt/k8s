## Overview
Alloy is deployed as a DaemonSet that collects logs from:
- Kubernetes pods
- Node syslog
- Node rehydration logs (`/var/log/rehydrate/*.log`)

Logs are forwarded to Loki for storage and querying.

## Configuration
The Alloy configuration is defined in values.yaml and includes:
- Pod log collection via Kubernetes API
- Node log collection from `/var/log/syslog`
- Rehydration log collection from `/var/log/rehydrate/*.log`
- Kubernetes events collection

## Notes
- Documentation: https://grafana.com/docs/alloy/latest/collect/logs-in-kubernetes/
- Runs as DaemonSet on all nodes
- No secrets or storage required