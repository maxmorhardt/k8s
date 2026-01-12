# Kube-Prometheus-Stack Setup

This deployment uses the `kube-prometheus-stack` Helm chart, which includes:
- **Prometheus Operator** - Manages Prometheus, Alertmanager, and ServiceMonitors
- **Prometheus** - Metrics collection and storage (14 day retention)
- **Grafana** - Metrics visualization with Authentik OIDC integration
- **Alertmanager** - Alert handling and routing
- **kube-state-metrics** - Kubernetes object metrics
- **prometheus-node-exporter** - Node-level system metrics

## Architecture

The stack uses the Prometheus Operator pattern with Custom Resource Definitions (CRDs):
- **ServiceMonitor** - Defines how to scrape metrics from Kubernetes services
- **PodMonitor** - Defines how to scrape metrics from pods
- **PrometheusRule** - Defines alerting and recording rules

## Prerequisites

1. **Kubernetes cluster** with sufficient resources
2. **Longhorn storage class** for persistent volumes
3. **Secrets** for Grafana:
   ```bash
   # Grafana admin credentials
   kubectl create secret generic grafana-credentials \
     --from-literal=admin-user=admin \
     --from-literal=admin-password=<your-password> \
     -n monitoring

   # Grafana environment variables (database + OIDC)
   kubectl create secret generic grafana-env \
     --from-literal=GF_DB_HOST=<postgres-host> \
     --from-literal=GF_DB_NAME=grafana \
     --from-literal=GF_DB_USER=grafana \
     --from-literal=GF_DB_PASSWORD=<db-password> \
     --from-literal=GF_OAUTH_CLIENT_ID=<authentik-client-id> \
     --from-literal=GF_OAUTH_CLIENT_SECRET=<authentik-client-secret> \
     -n monitoring
   ```

4. **TLS Certificate** for Grafana ingress:
   ```bash
   # maxstash.io-tls secret should already exist with wildcard cert
   ```

## Configuration

### Prometheus Settings
- **Scrape Interval**: 90s
- **Scrape Timeout**: 60s
- **Retention**: 14 days
- **Storage**: 50Gi Longhorn volume
- **Resources**: 250m CPU, 1Gi memory (requests)

### Grafana Settings
- **URL**: https://grafana.maxstash.io
- **Database**: PostgreSQL (CloudNativePG)
- **Authentication**: Authentik OIDC with role mapping
  - `grafana-admin` group → Admin role
  - Other authenticated users → Viewer role
- **Ingress**: Nginx ingress controller
- **Resources**: 250m CPU, 500Mi memory

### Custom Scrape Configs

To add custom application metrics, you have two options:

#### Option 1: ServiceMonitor (Recommended)
Create a ServiceMonitor CR in your application namespace:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  namespace: my-namespace
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
    - port: metrics
      interval: 90s
      path: /metrics
```

#### Option 2: Additional Scrape Configs
Add static scrape configs to `values-new.yaml` under `prometheus.prometheusSpec.additionalScrapeConfigs`:

```yaml
additionalScrapeConfigs:
  - job_name: 'my-app'
    scrape_interval: 90s
    static_configs:
      - targets: ['my-app-service.my-namespace.svc.cluster.local:8080']
```

## Deployment

Run the deployment script:
```bash
./deploy.sh
```

This will:
1. Install/upgrade kube-prometheus-stack in the `monitoring` namespace
2. Deploy Prometheus with Operator
3. Deploy Grafana with PostgreSQL backend and Authentik OIDC
4. Configure ServiceMonitor discovery across all namespaces

## Access

### Grafana Web UI
```
https://grafana.maxstash.io
```
Login with Authentik OIDC or admin credentials.

### Prometheus Web UI (Port Forward)
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Then visit http://localhost:9090
```

### Alertmanager Web UI (Port Forward)
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
# Then visit http://localhost:9093
```

## Migration from Standalone Prometheus

If migrating from a standalone Prometheus deployment:

1. **Export existing data** (optional):
   ```bash
   # Use Prometheus remote write or snapshot
   ```

2. **Update application ServiceMonitors**:
   The Prometheus Operator will automatically discover ServiceMonitor resources.

3. **Replace scrape configs**:
   - Convert manual scrape configs to ServiceMonitors (preferred)
   - Or add them to `additionalScrapeConfigs` in values-new.yaml

4. **Update Grafana datasource URLs**:
   ```
   Old: http://prometheus-server.monitoring.svc.cluster.local
   New: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
   ```

5. **Deploy new stack**:
   ```bash
   ./deploy.sh
   ```

6. **Remove old deployment**:
   ```bash
   helm uninstall prometheus -n monitoring
   helm uninstall grafana -n monitoring  # If separate
   ```

## Monitoring Applications

### Adding Metrics to Your Application

1. **Expose metrics endpoint** (e.g., `/metrics` on port 8080)

2. **Create ServiceMonitor**:
   ```yaml
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     name: ages-app
     namespace: ages
     labels:
       app: ages
   spec:
     selector:
       matchLabels:
         app: ages
     endpoints:
       - port: http
         path: /metrics
         interval: 90s
   ```

3. **Apply the ServiceMonitor**:
   ```bash
   kubectl apply -f servicemonitor.yaml
   ```

4. **Verify in Prometheus**:
   - Port-forward to Prometheus UI
   - Check Status → Targets
   - Your service should appear

## Troubleshooting

### Prometheus not scraping services
```bash
# Check ServiceMonitor is created
kubectl get servicemonitor -A

# Check Prometheus logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Verify service labels match ServiceMonitor selector
kubectl get svc -n <namespace> --show-labels
```

### Grafana database connection issues
```bash
# Check secret exists and has correct keys
kubectl get secret grafana-env -n monitoring -o yaml

# Check Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

### Grafana OIDC not working
```bash
# Verify Authentik client ID and secret
kubectl get secret grafana-env -n monitoring -o jsonpath='{.data.GF_OAUTH_CLIENT_ID}' | base64 -d

# Check Authentik provider configuration
# Redirect URIs should include: https://grafana.maxstash.io/login/generic_oauth
```

### Storage issues
```bash
# Check PVC status
kubectl get pvc -n monitoring

# Check Longhorn volumes
kubectl get pv | grep prometheus
```

## Notes

- Prometheus Operator automatically manages Prometheus configuration
- ServiceMonitors are the preferred way to add new scrape targets
- All components use Longhorn for persistent storage
- Grafana uses PostgreSQL for persistent storage (not PVC)
- Default retention is 14 days for Prometheus metrics
- Alertmanager retention is 120 hours