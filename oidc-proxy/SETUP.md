# kube-oidc-proxy Setup

## Overview

kube-oidc-proxy is a reverse proxy that authenticates requests to the Kubernetes API server using OpenID Connect (OIDC). It sits in front of your Kubernetes API server and validates OIDC tokens from identity providers like Authentik before forwarding authenticated requests to the API server.

**Why use this?**
- Enables user authentication via Authentik/OIDC instead of static certificates or service account tokens
- Integrates Kubernetes RBAC with your organization's identity provider
- Provides audit trail of API access by actual users
- Allows centralized access management through Authentik

## Architecture

```
kubectl (with OIDC token) 
  → kube-oidc-proxy.maxstash.io 
    → validates token with Authentik 
      → forwards to Kubernetes API server
```

## Prerequisites

1. **Authentik OIDC Provider** configured with:
   - Client ID and Client Secret
   - Redirect URI: Not required (token-based auth)
   - Scopes: `openid`, `email`, `profile`, `groups`

2. **Kubernetes RBAC** configured to map OIDC groups/users to roles

## Secrets Required

Create values file with OIDC configuration before deployment:

```yaml
# values.yaml additions
oidc:
  clientId: "<authentik-client-id>"
  issuerUrl: "https://login.maxstash.io/application/o/<app-slug>/"
  usernameClaim: "email"
  usernamePrefix: "oidc:"
  groupsClaim: "groups"
  groupsPrefix: "oidc:"
```

Alternatively, create a secret for sensitive values:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: kube-oidc-proxy-config
  namespace: kube-system
type: Opaque
stringData:
  client-id: "<authentik-client-id>"
  client-secret: "<authentik-client-secret>"
```

## Authentik Configuration

### 1. Create OIDC Provider

In Authentik:
1. Navigate to **Applications** → **Providers**
2. Create a new **OAuth2/OpenID Provider**:
   - **Name**: Kubernetes API
   - **Authorization flow**: Default implicit flow
   - **Client type**: Confidential
   - **Redirect URIs**: `http://localhost:8000` (for kubectl oidc-login plugin)
   - **Scopes**: `openid`, `email`, `profile`, `groups`

3. Copy the **Client ID** and **Client Secret**

### 2. Create Application

1. Navigate to **Applications**
2. Create new application:
   - **Name**: Kubernetes API
   - **Slug**: k8s-api
   - **Provider**: Select the provider created above

### 3. Configure Group Mappings

Ensure your Authentik groups are included in the token:
1. In the provider settings, ensure **Include groups in ID Token** is enabled
2. Users' group memberships will be passed in the `groups` claim

## Kubernetes RBAC Configuration

### Example: Give k8s-admins full cluster access

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oidc-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: Group
  name: oidc:k8s-admins
  apiGroup: rbac.authorization.k8s.io
```

### Example: Give k8s-developers namespace access

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: oidc-developers
  namespace: apps
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: edit
subjects:
- kind: Group
  name: oidc:k8s-developers
  apiGroup: rbac.authorization.k8s.io
```

## kubectl Configuration

### Using kubelogin Plugin

1. **Install kubelogin**:
   ```bash
   # macOS
   brew install int128/kubelogin/kubelogin
   
   # Linux
   kubectl krew install oidc-login
   ```

2. **Configure kubectl**:
   ```yaml
   apiVersion: v1
   kind: Config
   clusters:
   - cluster:
       server: https://kube-oidc-proxy.maxstash.io
       certificate-authority-data: <CA-CERT-DATA>
     name: k8s-oidc
   contexts:
   - context:
       cluster: k8s-oidc
       user: oidc
     name: k8s-oidc
   current-context: k8s-oidc
   users:
   - name: oidc
     user:
       exec:
         apiVersion: client.authentication.k8s.io/v1beta1
         command: kubectl
         args:
         - oidc-login
         - get-token
         - --oidc-issuer-url=https://login.maxstash.io/application/o/<app-slug>/
         - --oidc-client-id=<client-id>
         - --oidc-client-secret=<client-secret>
         - --oidc-extra-scope=email
         - --oidc-extra-scope=profile
         - --oidc-extra-scope=groups
   ```

3. **Authenticate**:
   ```bash
   kubectl get pods
   # Opens browser for Authentik login
   # Token is cached for subsequent requests
   ```

## Deployment

```bash
cd kube-oidc-proxy
./deploy.sh
```

## Verification

1. **Check deployment**:
   ```bash
   kubectl get pods -n kube-system -l app=kube-oidc-proxy
   kubectl get ingress -n kube-system
   ```

2. **Test authentication**:
   ```bash
   # Using kubelogin
   kubectl --context=k8s-oidc get nodes
   ```

## Troubleshooting

### Token not accepted
- Verify `issuerUrl` matches Authentik provider URL exactly (with trailing slash)
- Check `clientId` is correct
- Ensure token includes required claims (`email`, `groups`)

### RBAC permission denied
- Verify group name in ClusterRoleBinding matches `groupsPrefix + group_name`
- Check user is member of the group in Authentik
- Review Kubernetes audit logs

### Certificate errors
- If using self-signed certs, add `--oidc-issuer-skip-verify` to kubelogin args
- For production, use valid TLS certificates

## Security Considerations

- Store client secrets in Kubernetes Secrets, never in git
- Use HTTPS for all communication
- Regularly rotate client secrets
- Audit API access via Kubernetes audit logs
- Limit RBAC permissions following principle of least privilege
