## Prerequisites
```bash
# Create certificate for keycloak
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/O=<ORG>/CN=*.<DNS>"
```

## Notes
- Create user and database keycloak in postgres
- KEYCLOAK_DB_HOST_B64 looks like: jdbc:postgresql://dns:port/db-name | base64
- Create realms for user facing auth and developer auth (master will just be used as a root account)
- Theme docker image must exist or comment out initContainers