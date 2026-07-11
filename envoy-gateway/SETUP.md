# Envoy Gateway

Gateway API implementation fronting all HTTP traffic for `maxstash.io`. Replaces ingress-nginx.

Two pieces in `envoy-gateway-system`:

1. **envoy-gateway** — the upstream controller Helm chart (`oci://docker.io/envoyproxy/gateway-helm`). Also installs the Gateway API CRDs.
2. **manifests/** — plain YAML applied with `kubectl apply -f manifests/` (the upstream chart only installs the controller; the Gateway resources are ours): the `maxstash` GatewayClass, the `maxstash` Gateway (listeners for `maxstash.io` + `*.maxstash.io` on 443, http→https redirect on 80), the `EnvoyProxy` config (2 proxy replicas), and a `ClientTrafficPolicy` that resolves the real client IP from the Cloudflare hop (`numTrustedHops: 1`).

Apps attach by creating an `HTTPRoute` in their own namespace with `parentRefs` pointing at `maxstash` / `envoy-gateway-system` (see the app charts in the `charts` repo). The Gateway allows routes from all namespaces.

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

1. Install both releases (`./deploy.sh`). The envoy LoadBalancer service will sit pending on 80/443 while nginx still holds them — expected.
2. Deploy the HTTPRoute-based app charts (they can coexist with the old Ingress objects).
3. `helm uninstall ingress-nginx -n ingress-nginx` — klipper then binds 80/443 to envoy within seconds.
4. Delete the leftover Ingress objects / the `ingress-nginx` namespace and the `cloudflare-cidr` cronjob (nginx-specific).

## Notes

- Client IP: Cloudflare appends the real client IP to `X-Forwarded-For`; with exactly one trusted hop Envoy uses it for logs and rate limiting. Anyone bypassing Cloudflare and hitting the origin directly can spoof XFF — same trust model as the old nginx `proxy-real-ip-cidr` setup, minus the CIDR check. Lock origin access down at the router/firewall if this matters.
- Rate limits: per-route `BackendTrafficPolicy` (Local type) in each app chart replaces the nginx `limit-rps` annotations.
- Request body size caps moved into the apps themselves (`request_size` middleware); the gateway does not enforce one.
- WebSocket upgrades (`/ws` on squares-api) are enabled by default for HTTPRoutes in Envoy Gateway — no extra config.
