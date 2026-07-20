## Overview

Log storage in the `monitoring` namespace. Alloy ships logs here; Grafana queries them through
a Loki data source.

## Access

- Push endpoint: `http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push`

## Notes

- Logs are retained for 14 days.
