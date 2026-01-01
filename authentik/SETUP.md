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
  AUTHENTIK_POSTGRESQL__HOST: "db-postgresql.db.svc.cluster.local"
  AUTHENTIK_POSTGRESQL__PORT: "5432"
  
  # Bootstrap admin credentials (optional - only used on first setup)
  AUTHENTIK_BOOTSTRAP_PASSWORD: "CHANGE-ME-ADMIN-PASSWORD"
  AUTHENTIK_BOOTSTRAP_EMAIL: "admin@maxstash.io"
  
  # SMTP/Email configuration (optional - for email notifications)
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
   openssl rand -base64 60
   ```

2. Update `secret.yaml` with generated values

3. Apply secret:
   ```bash
   kubectl create namespace authentik
   kubectl apply -f secret.yaml
   ```

4. Deploy:
   ```bash
   ./deploy.sh
   ```

5. Access Authentik at `https://login.maxstash.io`
   - First user created automatically becomes admin
   - Or use bootstrap credentials from secret if set

## OIDC Endpoints

- **Discovery**: `https://login.maxstash.io/application/o/<app-slug>/.well-known/openid-configuration`
- **Authorization**: `https://login.maxstash.io/application/o/authorize/`
- **Token**: `https://login.maxstash.io/application/o/token/`
- **UserInfo**: `https://login.maxstash.io/application/o/userinfo/`