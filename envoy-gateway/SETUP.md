## Overview

Gateway API implementation fronting all HTTP traffic for `maxstash.io`. Replaces ingress-nginx.

Two pieces:

1. **envoy-gateway** (this directory) — the upstream controller chart, plus the Gateway API CRDs. Synced from [argocd/infra/envoy-gateway.yaml](../argocd/infra/envoy-gateway.yaml).
2. **maxstash-gateway** — chart in the `charts` repo with the actual Gateway resources: the `maxstash` GatewayClass + Gateway (listeners for `maxstash.io` and `*.maxstash.io` on 443, http→https redirect on 80), the `EnvoyProxy` config (2 proxy replicas), and a `ClientTrafficPolicy` resolving the real client IP from `X-Forwarded-For` against the trusted Cloudflare CIDRs. Synced from [argocd/apps/maxstash-gateway.yaml](../argocd/apps/maxstash-gateway.yaml).

Apps attach by creating an `HTTPRoute` in their own namespace with `parentRefs` pointing at `maxstash` / `envoy-gateway-system`. The Gateway allows routes from all namespaces.

## Prerequisites

The wildcard TLS secret must exist in `envoy-gateway-system`:

```bash
kubectl get secret maxstash.io-tls -n <existing-ns> -o yaml \
  | sed 's/namespace: .*/namespace: envoy-gateway-system/' \
  | kubectl apply -f -
```

## Notes

- Client IP: the `ClientTrafficPolicy` walks `X-Forwarded-For` right-to-left and takes the first address outside the trusted Cloudflare CIDRs - the same trust model as the old nginx `proxy-real-ip-cidr` setup. The `cloudflare-cidr` cronjob keeps the CIDR list current.
- Rate limits: per-route `BackendTrafficPolicy` (Local type) in each app chart replaces the nginx `limit-rps` annotations.
- Request body size caps moved into the apps themselves (`request_size` middleware); the gateway does not enforce one.
- WebSocket upgrades (`/ws` on squares-api) are enabled by default for HTTPRoutes in Envoy Gateway — no extra config.
