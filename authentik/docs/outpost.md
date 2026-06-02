# Embedded Outpost (Proxy Forward Auth)

Protect apps via nginx ingress forward auth using the embedded outpost (no separate deployment).

## Setup

1. **Applications → Providers → Create → Proxy Provider**
   - **Mode**: `Forward auth (single application)`
   - **External host**: `https://<your-app-domain>`
   - **Authorization flow**: `default-provider-authorization-implicit-consent`
2. **Applications → Applications → Create** — select the proxy provider; restrict access under **Bindings**.
3. **Outposts → Edit embedded outpost** — move the app to **Selected Applications** → **Update**.

## Nginx ingress annotations

Add to the app's ingress `values.yaml`:

```yaml
nginx.ingress.kubernetes.io/auth-url: "https://<your-authentik-domain>/outpost.goauthentik.io/auth/nginx"
nginx.ingress.kubernetes.io/auth-signin: "https://<your-app-domain>/outpost.goauthentik.io/start?rd=https://<your-app-domain>$request_uri"
nginx.ingress.kubernetes.io/auth-response-headers: "Set-Cookie,X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid"
nginx.ingress.kubernetes.io/auth-snippet: |
  proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
  proxy_set_header X-Forwarded-Host $http_host;
nginx.ingress.kubernetes.io/server-snippet: |
  location /outpost.goauthentik.io {
    proxy_pass http://authentik-server.authentik.svc.cluster.local:80;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
```
