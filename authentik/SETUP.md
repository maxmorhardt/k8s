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
  
  # Bootstrap admin credentials
  AUTHENTIK_BOOTSTRAP_PASSWORD: "CHANGE-ME-ADMIN-PASSWORD"
  AUTHENTIK_BOOTSTRAP_EMAIL: "admin@maxstash.io"
  
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
   - Use bootstrap credentials from secret

## OIDC Endpoints

- **Discovery**: `https://login.maxstash.io/application/o/<app-slug>/.well-known/openid-configuration`
- **Authorization**: `https://login.maxstash.io/application/o/authorize/`
- **Token**: `https://login.maxstash.io/application/o/token/`
- **UserInfo**: `https://login.maxstash.io/application/o/userinfo/`

## Post-Logout Redirect Policy

```python
import re
import logging
from urllib.parse import parse_qs, unquote

logger = logging.getLogger(__name__)

if not context.get('flow_plan'):
  logger.info('no flow_plan in context cannot redirect')
  return True

logger.info('starting invalid redirect policy')
try:
  logger.info('getting redirect uri')
  query = parse_qs(request.http_request.GET.get('query'))
  redirect_uris = query.get('post_logout_redirect_uri', [])

  redirect_uri = None
  if len(redirect_uris) > 0:
    redirect_uri = unquote(redirect_uris[0])
    logger.info('redirect_uri: %s', redirect_uri)
  
  if redirect_uri:
    logger.info('redirect_uri exists checking if valid')
    if (re.match(r'^https://[a-zA-Z0-9\-]+\.maxstash\.io(/.*)?$', redirect_uri) or 
        re.match(r'^http://localhost:3000(/.*)?$', redirect_uri)):
      logger.info('valid redirect_uri redirecting to %s', redirect_uri)
      context['flow_plan'].redirect(redirect_uri)
      return True

  logger.info('getting provider redirect uri')
  application = context.get('application')
  provider = application.get_provider()
  provider_logout_uri = provider.logout_uri
  logger.info('provider_logout_uri: %s', provider_logout_uri)
  
  if provider_logout_uri:
    logger.info('redirecting to provider_logout_uri %s', provider_logout_uri)
    context['flow_plan'].redirect(provider_logout_uri)
    return True
  
  logger.info('no valid redirect uri using default login.maxstash.io')
  context['flow_plan'].redirect("https://login.maxstash.io")
  return True
  
except Exception as err:
  logger.info('error in policy: %s', err)
  context['flow_plan'].redirect("https://login.maxstash.io")
  return True
```

## Branding

### Custom CSS

```css
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
    color 9999s ease-in-out 0s !important;
}

.pf-c-login__footer {
  display: none !important;
}

.ak-login-container {
  height: 100% !important;
}

.pf-c-login__main {
  border-radius: 1rem !important;
}

.pf-c-login__main-footer-band {
  border-radius: 0 0 1rem 1rem !important;
}

.pf-c-background-image::before {
  background: linear-gradient(135deg, #000000 0%, #0f0f0f 50%, #000000 100%) !important;
}
```

### Attributes

```yaml
settings:
  theme:
    base: dark
```