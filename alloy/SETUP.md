## Overview

Alloy runs as a DaemonSet in `monitoring`, collecting logs from:
- Kubernetes pods
- kured pre-reboot logs (`/var/log/kured/*.log`)
- network-watchdog systemd journal (`{job="node/network-watchdog"}`)

Logs are forwarded to Loki for storage and querying.

## Notes
- Documentation: https://grafana.com/docs/alloy/latest/collect/logs-in-kubernetes/
