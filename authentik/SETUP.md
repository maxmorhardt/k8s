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

12. Create user details flow (read-only):
    - Go to **Flows & Stages > Prompts** and create three prompts:
      - Name `user-details-email`, field key `email`, label `Email`, type `Text`, initial value `return user.email`, order `0`, **Interpret initial value as expression: ON**
      - Name `user-details-name`, field key `name`, label `Name`, type `Text (read-only)`, initial value `return user.name`, order `1`, **Interpret initial value as expression: ON**
      - Name `user-details-username`, field key `username`, label `Username`, type `Text (read-only)`, initial value `return user.username`, order `2`, **Interpret initial value as expression: ON**
    - Go to **Flows & Stages > Stages > Create > Prompt Stage**, name `user-details`, add all prompts
    - Go to **Flows & Stages > Flows > Create**:
      - Slug: `user-details`, designation: `Stage Configuration`, authentication: `Require authentication`
    - Open the flow > **Stage Bindings > Bind Stage**, select `user-details` at order `0`
    - Do **not** add a User Write stage
    - Go to **System > Brands > Edit brand > Default flows**, set **User settings flow** to `user-details`

## Branding

### Custom CSS

```css
/* Hide locale selector and footer links */
ak-flow-executor::part(locale-select) {
  display: none;
}

ak-brand-links {
  display: none !important;
}

/* Round the main card */
ak-flow-executor::part(main) {
  border-radius: 0.6rem;
}

/* Position and size the branding/logo area */
ak-flow-executor::part(branding) {
  max-height: 60px;
  padding-top: 5rem;
  margin-bottom: 1.5rem;
}

/* Center and constrain the logo image */
.branding-logo {
  display: block;
  width: 300px;
  max-width: 100%;
  height: auto;
  margin: 1.5rem auto 1rem;
}

/* Remove drop shadow from the login card */
.pf-c-login__main {
  --pf-c-login__main--BoxShadow: none !important;
}

/* Hide the page-credentials tab */
[slot="page-credentials"],
li[part="tab-item"]:has(button[name="page-credentials"]) {
  display: none !important;
}

/* Reduce space above the submit button */
.pf-c-form__group.pf-m-action {
  margin-top: 0.05rem;
}

/* Add space between footer links */
.pf-c-login__main-footer-band-item + .pf-c-login__main-footer-band-item {
  margin-top: 0.75rem;
}

/* Add padding below the last footer link */
.pf-c-login__main-footer-band {
  padding-bottom: .5rem !important;
}

/* Fix autofill background on dark theme */
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

## Embedded Outpost (Proxy Forward Auth)

Used to protect applications via nginx ingress forward auth without a separate outpost deployment.

### Create a Proxy Provider

**Applications → Providers → Create → Proxy Provider**

- **Mode**: `Forward auth (single application)`
- **External host**: `https://<your-app-domain>`
- **Authorization flow**: `default-provider-authorization-implicit-consent`

### Create an Application

**Applications → Applications → Create**

- **Provider**: select the proxy provider above
- Add policy/group bindings under the **Bindings** tab to restrict access

### Add Application to Outpost

**Outposts → Edit embedded outpost** → move the application to **Selected Applications** → **Update**

### Nginx Ingress Annotations

Add to the application's ingress `values.yaml`:

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

## OIDC Endpoints

- **Discovery**: `https://login.maxstash.io/application/o/<app-slug>/well-known/openid-configuration`
- **Authorization**: `https://login.maxstash.io/application/o/authorize/`
- **Token**: `https://login.maxstash.io/application/o/token/`
- **UserInfo**: `https://login.maxstash.io/application/o/userinfo/`