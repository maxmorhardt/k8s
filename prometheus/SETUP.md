## Storage
1. SSH into node that will host Prometheus (max-worker)
2. Create directory /data/prometheus with 1000:1000 owner/group
   ```bash
   sudo mkdir -p /data/prometheus
   sudo chown -R 1000:1000 /data/prometheus
   ```

## Notes
- Apply storage.yaml before running ./deploy.sh
- Ingress is not enabled -- visualize with Grafana and use kube DNS
  - Example: `http://prometheus-server.monitoring.svc.cluster.local`
- To access locally:
  ```bash
  kubectl port-forward -n monitoring svc/prometheus-server 9090:80
  # Then visit http://localhost:9090
  ```