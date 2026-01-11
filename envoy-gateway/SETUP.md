# Envoy Gateway Setup

## Overview

Envoy Gateway provides ingress capabilities using the Kubernetes Gateway API, replacing the deprecated nginx-ingress-controller. This setup includes Cloudflare proxy support for proper client IP detection.

## Installation

```bash
cd envoy-gateway
./deploy.sh
```

This will:
1. Install Gateway API CRDs (v1.2.1)
2. Install Envoy Gateway via Helm (v1.2.4)
3. Configure Cloudflare proxy settings
4. Create the main Gateway resource

## Components

### GatewayClass
- **Name**: `eg`
- **Controller**: Envoy Gateway
- **Config**: Uses `cloudflare-proxy` EnvoyProxy config for Cloudflare support

### Gateway
- **Name**: `cloudflare-gateway`
- **Namespace**: `envoy-gateway-system`
- **Ports**: 80 (HTTP), 443 (HTTPS)
- **TLS**: Terminate with cert-manager certificates

### ClientTrafficPolicy
Handles Cloudflare proxy headers:
- Trusts `CF-Connecting-IP` header for real client IP
- Respects `X-Forwarded-For` with 1 trusted hop
- Automatically applies to all routes through the Gateway

## Cloudflare Configuration

The setup automatically handles Cloudflare's proxy headers:
- `CF-Connecting-IP`: Real client IP from Cloudflare
- `X-Forwarded-For`: Forwarding chain
- `X-Forwarded-Proto`: Original protocol (HTTP/HTTPS)
- `X-Forwarded-Host`: Original host header

No need to manually configure trusted IP ranges - Cloudflare authentication happens at the DNS/tunnel level.

## Converting Ingress to HTTPRoute

Example conversion from Ingress to HTTPRoute:

**Old (Ingress):**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: monitoring
spec:
  ingressClassName: nginx
  rules:
  - host: grafana.maxstash.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 80
  tls:
  - hosts:
    - grafana.maxstash.io
    secretName: maxstash.io-tls
```

**New (HTTPRoute):**
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: grafana
  namespace: monitoring
spec:
  parentRefs:
  - name: cloudflare-gateway
    namespace: envoy-gateway-system
  hostnames:
  - grafana.maxstash.io
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: grafana
      port: 80
```

TLS certificates are handled at the Gateway level, not per-route.

## Service Access

The Gateway LoadBalancer service exposes ports 80 and 443:

```bash
# Get the LoadBalancer IP/hostname
kubectl get svc -n envoy-gateway-system envoy-cloudflare-gateway
```

Point your Cloudflare DNS to this IP address.

## Verification

```bash
# Check Gateway status
kubectl get gateway -n envoy-gateway-system cloudflare-gateway

# Check HTTPRoutes across all namespaces
kubectl get httproute -A

# View Envoy Gateway logs
kubectl logs -n envoy-gateway-system deployment/envoy-gateway -f

# Test client IP detection
curl -H "CF-Connecting-IP: 1.2.3.4" http://your-service.maxstash.io
```

## Resources

- **Envoy Gateway**: ~100m CPU, ~128Mi RAM
- **Envoy Proxy**: ~50m CPU per instance, ~128Mi RAM per instance
- **Total**: ~150m CPU, ~256Mi RAM

## Migration Notes

Key differences from nginx-ingress:
1. **HTTPRoute instead of Ingress**: More expressive routing capabilities
2. **Policy-based config**: ClientTrafficPolicy, BackendTrafficPolicy instead of annotations
3. **Namespace-aware**: Routes in any namespace can reference the Gateway
4. **Type-safe**: No more string-based annotations, proper API validation
5. **No snippets**: Custom behavior via proper extension points, not raw config

## References

- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [Envoy Gateway Documentation](https://gateway.envoyproxy.io/)
- [Cloudflare IP Ranges](https://www.cloudflare.com/ips/)
