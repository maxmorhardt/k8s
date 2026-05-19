## Overview
Alloy is deployed as a DaemonSet that collects logs from:
- Kubernetes pods
- kured pre-reboot logs (`/var/log/kured/*.log`)

Logs are forwarded to Loki for storage and querying.

## Notes
- Documentation: https://grafana.com/docs/alloy/latest/collect/logs-in-kubernetes/
