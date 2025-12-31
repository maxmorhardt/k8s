# Zitadel Setup

## Prerequisites

### PostgreSQL Database
1. Create zitadel database and user in PostgreSQL:
```sql
CREATE DATABASE zitadel;
CREATE USER zitadel WITH PASSWORD 'your-password-here';
GRANT ALL PRIVILEGES ON DATABASE zitadel TO zitadel;
\c zitadel
GRANT ALL ON SCHEMA public TO zitadel;
```

### Secrets Required

**1. Create masterkey secret:**
```bash
# Generate masterkey (32 characters)
MASTERKEY=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)

kubectl create secret generic zitadel-masterkey \
  --namespace zitadel \
  --from-literal=masterkey=$MASTERKEY
```

**2. Create database password secret:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: zitadel-db-password
  namespace: zitadel
type: Opaque
stringData:
  password: <your-postgres-password>
```

Or use environment variable approach:
```bash
kubectl create secret generic zitadel-env \
  --namespace zitadel \
  --from-literal=ZITADEL_DATABASE_POSTGRES_USER_PASSWORD=<your-password> \
  --from-literal=ZITADEL_DATABASE_POSTGRES_ADMIN_PASSWORD=<admin-password>
```

## Initial Setup

1. **Deploy Zitadel:**
```bash
./deploy.sh
```

2. **Wait for initialization** (init and setup jobs will run):
```bash
kubectl get jobs -n zitadel
kubectl logs -n zitadel job/zitadel-init
kubectl logs -n zitadel job/zitadel-setup
```

3. **Get IAM Admin credentials:**
```bash
# Get the machine key (JWT)
kubectl get secret -n zitadel iam-admin -o jsonpath='{.data.zitadel-admin-sa\.json}' | base64 -d

# Or get the PAT if configured
kubectl get secret -n zitadel iam-admin-pat -o jsonpath='{.data.pat}' | base64 -d
```

4. **Access Console:**
- URL: `https://login.maxstash.io`
- Login with the first user you create (becomes admin)

## Application Integration

### Create Application (OIDC)

Use Zitadel Console or API:

**Via Console:**
1. Go to `https://login.maxstash.io/ui/console`
2. **Projects** → **Create New Project** → "Internal Apps"
3. **Applications** → **New** → **Web Application**
4. **Type**: OIDC
5. **Redirect URIs**: Add your app callbacks
6. **Post Logout URIs**: Add your app URLs
7. Save and copy **Client ID** and **Client Secret**

### Jenkins OIDC Configuration

**Zitadel Console:**
- Project: Internal Apps
- Application: Jenkins
- Type: Web
- Redirect URI: `https://jenkins.maxstash.io/securityRealm/finishLogin`
- Grant Types: Authorization Code
- Response Type: Code

**Jenkins Configuration:**
- Client ID: `<from-zitadel>`
- Client Secret: `<from-zitadel>`
- Configuration URL: `https://login.maxstash.io/.well-known/openid-configuration`
- Or manual:
  - Authorization Endpoint: `https://login.maxstash.io/oauth/v2/authorize`
  - Token Endpoint: `https://login.maxstash.io/oauth/v2/token`
  - Userinfo Endpoint: `https://login.maxstash.io/oidc/v1/userinfo`

### Grafana OIDC Configuration

```yaml
env:
  - name: GF_AUTH_GENERIC_OAUTH_ENABLED
    value: "true"
  - name: GF_AUTH_GENERIC_OAUTH_NAME
    value: "Zitadel"
  - name: GF_AUTH_GENERIC_OAUTH_CLIENT_ID
    value: "<from-zitadel>"
  - name: GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET
    value: "<from-zitadel>"
  - name: GF_AUTH_GENERIC_OAUTH_SCOPES
    value: "openid profile email"
  - name: GF_AUTH_GENERIC_OAUTH_AUTH_URL
    value: "https://login.maxstash.io/oauth/v2/authorize"
  - name: GF_AUTH_GENERIC_OAUTH_TOKEN_URL
    value: "https://login.maxstash.io/oauth/v2/token"
  - name: GF_AUTH_GENERIC_OAUTH_API_URL
    value: "https://login.maxstash.io/oidc/v1/userinfo"
```

### React App (Squares)

```typescript
const oidcConfig: AuthProviderProps = {
  authority: 'https://login.maxstash.io',
  client_id: '<your-client-id>',
  redirect_uri: import.meta.env.PROD 
    ? 'https://squares.maxstash.io' 
    : 'http://localhost:3000',
  post_logout_redirect_uri: import.meta.env.PROD 
    ? 'https://squares.maxstash.io' 
    : 'http://localhost:3000',
  scope: 'openid profile email',
  automaticSilentRenew: true,
  userStore: new WebStorageStateStore({ store: window.localStorage }),
  onSigninCallback: () => {
    window.history.replaceState({}, document.title, window.location.pathname);
  },
};
```

## Resource Usage

**Total resources:**
- Main deployment: 2 pods × 500m CPU × 1Gi = **1 CPU, 2GB**
- Login UI: 2 pods × 250m CPU × 512Mi = **500m CPU, 1GB**
- **Total: 1.5 CPUs, 3GB** (50% less than Authentik)

**Supports:**
- ~10,000-15,000 concurrent users
- Much faster than Authentik (Go vs Python)

## Migration from Authentik

**User Migration:**
- Export users from Authentik
- Use Zitadel User Import API
- Or bulk create via API/Console

**Applications:**
- Recreate as Projects/Applications in Zitadel
- Update client IDs/secrets in apps
- Test each integration

## Troubleshooting

**Check database connection:**
```bash
kubectl logs -n zitadel deployment/zitadel
```

**Check init/setup jobs:**
```bash
kubectl describe job -n zitadel zitadel-init
kubectl describe job -n zitadel zitadel-setup
```

**Reset database (start fresh):**
```sql
DROP DATABASE zitadel;
CREATE DATABASE zitadel;
GRANT ALL PRIVILEGES ON DATABASE zitadel TO zitadel;
```

**Re-run init/setup:**
```bash
helm upgrade zitadel zitadel/zitadel --reuse-values --namespace zitadel --force
```

## Key Differences from Authentik

- **Organizations/Projects** instead of flat apps
- **Grants** for user-to-project access
- **Actions** instead of Policies (JavaScript/webhooks)
- **No built-in LDAP provider**
- **No proxy provider** - OIDC only
- **Better multi-tenancy** support
- **Faster performance** (Go vs Python)
