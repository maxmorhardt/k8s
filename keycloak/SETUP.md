## Secrets Required

Create the `keycloak-credentials` and `keycloak-tls` secrets manually before deployment:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: keycloak-credentials
  namespace: keycloak
type: Opaque
data:
  db-password: <base64-encoded-db-password>
```

```bash
# Generate TLS certificate for Keycloak
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/O=maxstash/CN=auth.maxstash.io"

kubectl create secret tls keycloak-tls --cert=cert.pem --key=key.pem -n keycloak
```

## Notes
- Create user and database `keycloak` in Postgres before deployment
- Create realms for user-facing auth and developer auth (master realm is for root admin only)
- Theme docker image must exist or comment out initContainers in values.yaml