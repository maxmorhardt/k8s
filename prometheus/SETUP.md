## Storage
1. SSH into node that will host Prometheus (max-worker)
2. Create directory /data/prometheus with 1000:1000 owner/group
   ```bash
   sudo mkdir -p /data/prometheus
   sudo chown -R 1000:1000 /data/prometheus
   ```

## Secrets Required

Create the `jenkins-api-credentials` secret manually before deployment:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-api-credentials
  namespace: maxstash-global
type: Opaque
data:
  username: <base64-encoded-jenkins-username>
  password: <base64-encoded-jenkins-api-token>
```

## Notes
- Apply storage.yaml before running ./deploy.sh
- Ingress is not enabled -- visualize with Grafana and use kube DNS
  - Example: `http://prometheus-server.maxstash-global.svc.cluster.local`
- To access locally:
  ```bash
  kubectl port-forward -n maxstash-global svc/prometheus-server 9090:9090
  # Then visit http://localhost:9090
  ```