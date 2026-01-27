## Secrets Required

Create the `zitadel-masterkey` secret for ZITADEL encryption:

```yaml
apiVersion: v1
kind: Secret
metadata:
	name: zitadel-masterkey
	namespace: zitadel
type: Opaque
stringData:
	masterkey: <your-masterkey>
```

**Command to generate a random masterkey:**

```sh
ZITADEL_MASTERKEY="$(LC_ALL=C tr -dc '[:graph:]' </dev/urandom | head -c 32)"
```

Create the `zitadel-env` secret for environment configuration
```yaml
apiVersion: v1
kind: Secret
metadata:
	name: zitadel-env
	namespace: zitadel
type: Opaque
data:
	ZITADEL_DATABASE_POSTGRES_ADMIN_PASSWORD: <admin-password>
	ZITADEL_DATABASE_POSTGRES_ADMIN_SSL_MODE: <ssl-mode>
	ZITADEL_DATABASE_POSTGRES_ADMIN_USERNAME: <admin-username>
	ZITADEL_DATABASE_POSTGRES_DATABASE: <db-name>
	ZITADEL_DATABASE_POSTGRES_HOST: <db-host>
	ZITADEL_DATABASE_POSTGRES_PORT: <db-port>
	ZITADEL_DATABASE_POSTGRES_USER_PASSWORD: <user-password>
	ZITADEL_DATABASE_POSTGRES_USER_SSL_MODE: <ssl-mode>
	ZITADEL_DATABASE_POSTGRES_USER_USERNAME: <user-username>
	ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORD: <initial-admin-password>
	ZITADEL_FIRSTINSTANCE_ORG_HUMAN_USERNAME: <initial-admin-username>
```

## Initial Setup

1. **Access the ZITADEL UI:**
	- Open: https://login.maxstash.io
	- Login using credentials:
  	- <admin-user>@zitadel.login.maxstash.io
  	- <admin-password>
	- When prompted enroll in MFA

2. **Create and configure the maxstash organization:**
	- Go to "Organizations" and create a new org named `maxstash`.
	- Set `maxstash` as the default organization
	- In Verified Domains change primary to maxstash.io

3. **Domain and login name pattern:**
	- Go to Default Settings → Domain Settings.
	- **Ensure** "Add organization domain as suffix to loginnames" is **unchecked**.

4. **Configure login form fields for maxstash org:**
	- Go to Settings → Login Form (for the `maxstash` org).
	- Set the following options:
	  - [x] Username and Password allowed
	  - [x] User Registration allowed
	  - [ ] Organization Registration allowed
	  - [x] External Login allowed
	  - [ ] Password Reset hidden
	  - [x] Domain Discovery allowed
	  - [ ] Ignore unknown Usernames
	  - [ ] Disable Email Login
	  - [x] Disable Phone Login

5. **Restrict login form fields for the zitadel org:**
	- Go to Settings → Login Form (for the `zitadel` org).
	- Set the following options:
	  - [x] Username and Password allowed
	  - [ ] User Registration allowed
	  - [ ] External Login allowed
	  - [x] Password Reset hidden
	  - [ ] Domain Discovery allowed
	  - [x] Ignore unknown Usernames
	  - [x] Disable Email Login
	  - [x] Disable Phone Login

6. **Branding and dark mode:**
	- Go to Default Settings → Branding.
	- Enable **Dark Mode only**.
	- Under Advanced Behavior, check:
	  - [x] Hide Loginname suffix
	  - [x] Hide Watermark

7. **Configure SMTP:**
  - Go to Default Settings → SMTP and enter the SMTP credentials

8. **Create projects:**
  - `maxstash`
  - `maxstash-dev`

9. **Create admin roles and authorize users:**
	- For each project, create appropriate admin roles (grafana-admin, squares-admin, etc.)
	- Authorize user with these roles

10. **Project settings:**
	- For each project, go to Settings and ensure:
	  - [x] Assert Roles on Authentication
	  - [ ] Check authorization on Authentication
	  - [ ] Check for Project on Authentication

11. **Application (app) settings:**
	- For each app in your projects, go to Token Settings and ensure:
	  - Auth Token Type: Bearer Token
	  - [x] User roles inside ID Token
	  - [x] User Info inside ID Token
	- Under Grant Types, ensure:
	  - [x] Refresh Token is enabled