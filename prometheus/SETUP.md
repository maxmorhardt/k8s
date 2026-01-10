## Notes
- Ingress is not enabled -- visualize with Grafana and use kube DNS
  - Example: `http://prometheus-server.monitoring.svc.cluster.local`
- To access locally:
  ```bash
  kubectl port-forward -n monitoring svc/prometheus-server 9090:80
  # Then visit http://localhost:9090
  ```