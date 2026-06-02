# Deployment

Standing up authentik. Post-deploy config: [initial-config.md](initial-config.md).

## Secrets

Copy [`secret.example.yaml`](../secret.example.yaml) to `secret.yaml` (gitignored), fill in real values, generate the key with `openssl rand -base64 60` (**save it**). Holds the secret key, PostgreSQL primary + read-replica creds, and SMTP settings.

> Omit the `AUTHENTIK_POSTGRESQL__READ_REPLICAS__*` keys on the **initial** deploy — add them once the replica exists.

## Deploy

1. Create the authentik database + user in PostgreSQL (matching the secret).
2. Apply:
   ```bash
   kubectl create namespace authentik
   kubectl apply -f secret.yaml
   ./deploy.sh
   ```
3. Create the admin account at `https://login.maxstash.io/if/flow/initial-setup/`.
