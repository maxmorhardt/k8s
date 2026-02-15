## Secrets Required

Create the `authentik` secret manually before deployment:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: authentik
  namespace: authentik
type: Opaque
stringData:
  # Generate with: openssl rand -base64 60
  AUTHENTIK_SECRET_KEY: "CHANGE-ME-GENERATE-RANDOM-KEY"
  AUTHENTIK_POSTGRESQL__USER: "authentik"
  AUTHENTIK_POSTGRESQL__PASSWORD: "CHANGE-ME-PASSWORD"
  AUTHENTIK_POSTGRESQL__NAME: "authentik"
  AUTHENTIK_POSTGRESQL__HOST: "postgres-cluster-rw.cnpg-database.svc.cluster.local"
  AUTHENTIK_POSTGRESQL__PORT: "5432"
  
  # Read replica configuration (DO NOT CONFIGURE ON INITIAL DEPLOYMENT)
  AUTHENTIK_POSTGRESQL__READ_REPLICAS__0__HOST: "postgres-cluster-ro.cnpg-database.svc.cluster.local"
  AUTHENTIK_POSTGRESQL__READ_REPLICAS__0__NAME: "authentik"
  AUTHENTIK_POSTGRESQL__READ_REPLICAS__0__USER: "authentik"
  AUTHENTIK_POSTGRESQL__READ_REPLICAS__0__PASSWORD: "CHANGE-ME-PASSWORD"
  AUTHENTIK_POSTGRESQL__READ_REPLICAS__0__PORT: "5432"
  
  # SMTP/Email configuration
  AUTHENTIK_EMAIL__HOST: "smtp.example.com"
  AUTHENTIK_EMAIL__PORT: "587"
  AUTHENTIK_EMAIL__USERNAME: "smtp-user@example.com"
  AUTHENTIK_EMAIL__PASSWORD: "CHANGE-ME-SMTP-PASSWORD"
  AUTHENTIK_EMAIL__USE_TLS: "true"
  AUTHENTIK_EMAIL__USE_SSL: "false"
  AUTHENTIK_EMAIL__TIMEOUT: "30"
  AUTHENTIK_EMAIL__FROM: "authentik@maxstash.io"
```

## PostgreSQL Database Setup

Create the Authentik database and user in PostgreSQL

## Initial Setup

1. Generate secret key:
   ```bash
	 # SAVE THIS IMMEDIATELY
   openssl rand -base64 60
   ```

2. Create `secret.yaml` with generated values

3. Apply secret:
   ```bash
   kubectl create namespace authentik
   kubectl apply -f secret.yaml
   ```

4. Deploy:
   ```bash
   ./deploy.sh
   ```

5. Access Authentik at `https://login.maxstash.io/if/flow/initial-setup/`

6. Configure system settings:
   - Go to **System > Settings**
   - Set **Default session duration** to `12 hours`
     - Change this session duration in login stages as well
   - Set **Event retention** to `90 days`

7. Update password policy:
   - Go to **Policies > Password Policies**
   - Edit the default policy to use **Static Rules** only
   - Set **Minimum length** to `8`

8. Create recovery flow

9. Create enrollment flow with Cloudflare Turnstile

10. Create non akadmin user and admin groups for apps

11. Configure brand for login.maxstash.io (new default) - see below config

## Branding

### Custom CSS

```css
ak-flow-executor::part(locale-select) {
  display: none;
}

ak-brand-links {
  display: none !important;
}

ak-flow-executor::part(branding) {
  max-height: 60px;
  padding-top: 6rem;
  margin-bottom: 0.5rem;
}

ak-flow-executor::part(main) {
  border-radius: 0.75rem;
}

input:-webkit-autofill,
input:-webkit-autofill:focus,
input:-webkit-autofill:hover,
input:-webkit-autofill:active,
textarea:-webkit-autofill,
select:-webkit-autofill {
  -webkit-box-shadow: 0 0 0 1000px transparent inset !important;
  box-shadow: 0 0 0 1000px transparent inset !important;
  -webkit-text-fill-color: inherit !important;
  caret-color: inherit !important;
  transition:
    background-color 9999s ease-in-out 0s,
    color 9999s ease-in-out 0s;
}
```

### Attributes

```yaml
settings:
  theme:
    base: dark
```

## OIDC Endpoints

- **Discovery**: `https://login.maxstash.io/application/o/<app-slug>/.well-known/openid-configuration`
- **Authorization**: `https://login.maxstash.io/application/o/authorize/`
- **Token**: `https://login.maxstash.io/application/o/token/`
- **UserInfo**: `https://login.maxstash.io/application/o/userinfo/`