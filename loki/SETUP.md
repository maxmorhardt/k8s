## Storage
1. SSH into node that will host Loki (max-worker-2)
2. Create directory /data/loki with 10001:10001 owner/group
   ```bash
   sudo mkdir -p /data/loki
   sudo chown -R 10001:10001 /data/loki
   ```

## Notes
- Apply storage.yaml before running ./deploy.sh
- Loki push endpoint: `http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push`
- Logs are retained for 30 days by default
- Query logs via Grafana data source