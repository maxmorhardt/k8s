## Secrets Required

Create the `keycloak-credentials` secret manually before deployment:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: keycloak-credentials
  namespace: maxstash-global
type: Opaque
data:
  admin-username: <base64-encoded-admin-username>
  admin-password: <base64-encoded-admin-password>
  db-username: <base64-encoded-db-username>
  db-password: <base64-encoded-db-password>
  db-host: <base64-encoded-jdbc-url>  # Format: jdbc:postgresql://<host>:<port>/<db-name>
  cert.pem: <base64-encoded-tls-certificate>
  key.pem: <base64-encoded-tls-private-key>
```

## Prerequisites
```bash
# Generate TLS certificate for Keycloak
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/O=<ORG>/CN=auth.maxstash.io"
```

## Notes
- Create user and database `keycloak` in Postgres before deployment
- KEYCLOAK_DB_HOST_B64 format: `jdbc:postgresql://<host>:<port>/<db-name>` (base64 encoded)
- Create realms for user-facing auth and developer auth (master realm is for root admin only)
- Theme docker image must exist or comment out initContainers in values.yaml
- Runs on max-worker-2 node