# Envoy Gateway

Gateway API implementation fronting all HTTP traffic for `maxstash.io`. Replaces ingress-nginx.

Two pieces:

1. **envoy-gateway** (this directory) — the upstream controller Helm chart (`oci://docker.io/envoyproxy/gateway-helm`) deployed to `envoy-gateway-system`. Also installs the Gateway API CRDs. Deploy with `./deploy.sh` or the Envoy Gateway CD workflow.
2. **maxstash-gateway** — chart in the `charts` repo (`charts/maxstash-gateway`) with the actual Gateway resources: the `maxstash` GatewayClass + Gateway (listeners for `maxstash.io` and `*.maxstash.io` on 443, http→https redirect on 80), the `EnvoyProxy` config (2 proxy replicas), and a `ClientTrafficPolicy` resolving the real client IP from `X-Forwarded-For` against the trusted Cloudflare CIDRs. Deploy via the charts repo Chart CD workflow with namespace `envoy-gateway-system`.

Apps attach by creating an `HTTPRoute` in their own namespace with `parentRefs` pointing at `maxstash` / `envoy-gateway-system`. The Gateway allows routes from all namespaces.

## Routing model

- UIs: hostname-per-app (`squares.maxstash.io`, `olympics.maxstash.io`, `maxstash.io`).
- APIs: single hostname `api.maxstash.io`, path-per-app (`/squares`, `/olympics`). Routes strip the prefix (`ReplacePrefixMatch: /`) so containers stay prefix-agnostic.
- Auth: `login.maxstash.io` → Dex.

## Prerequisites

The wildcard TLS secret must exist in `envoy-gateway-system`:

```bash
kubectl get secret maxstash.io-tls -n <existing-ns> -o yaml \
  | sed 's/namespace: .*/namespace: envoy-gateway-system/' \
  | kubectl apply -f -
```

## Cutover from ingress-nginx

k3s klipper-lb can only bind host ports 80/443 for one LoadBalancer service. Order matters:

1. Deploy the controller (`./deploy.sh`) and the `maxstash-gateway` chart. The envoy LoadBalancer service will sit pending on 80/443 while nginx still holds them — expected.
2. Deploy the HTTPRoute-based app charts (they can coexist with the old Ingress objects).
3. `helm uninstall ingress-nginx -n ingress-nginx` — klipper then binds 80/443 to envoy within seconds.
4. Delete the leftover Ingress objects / the `ingress-nginx` namespace.

## Notes

- Client IP: the `ClientTrafficPolicy` walks `X-Forwarded-For` right-to-left and takes the first address outside the trusted Cloudflare CIDRs - the same trust model as the old nginx `proxy-real-ip-cidr` setup. The `cloudflare-cidr` cronjob keeps the CIDR list current.
- Rate limits: per-route `BackendTrafficPolicy` (Local type) in each app chart replaces the nginx `limit-rps` annotations.
- Request body size caps moved into the apps themselves (`request_size` middleware); the gateway does not enforce one.
- WebSocket upgrades (`/ws` on squares-api) are enabled by default for HTTPRoutes in Envoy Gateway — no extra config.
