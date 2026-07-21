## Overview

OIDC identity provider at `https://login.maxstash.io`, federating **Google** and **GitHub** sign-in for all maxstash apps. Replaces Authentik.

One Helm release in the `dex` namespace: the upstream chart (`dex/dex` from https://charts.dexidp.io), config in [values.yaml](values.yaml). The chart's built-in `httpRoute` attaches `login.maxstash.io` to the `maxstash` Gateway.

## One-time setup

1. **Postgres**: create the `dex` database and user on the CNPG cluster:
   ```sql
   CREATE USER dex WITH PASSWORD '...';
   CREATE DATABASE dex OWNER dex;
   ```
2. **Google OAuth client**
3. **GitHub OAuth app**
4. Create the secret: `cp secret.example.yaml secret.yaml`, fill it in, then seal it and
   delete the plaintext (see [sealed-secrets/SETUP.md](../sealed-secrets/SETUP.md))
5. Deploy: merge to `main` - Argo CD syncs the [dex Application](../argocd/infra/dex.yaml)
   and the sealed `dex-env` secret.

## Adding a new app

1. Add a `staticClients` entry: SPAs get `public: true` + exact redirect URIs; server-side apps get `secretEnv: <APP>_CLIENT_SECRET` plus a new key in `dex-env` (`openssl rand -hex 32`).
2. Redeploy dex. The app's OIDC config: issuer `https://login.maxstash.io`, its client id, scopes `openid profile email offline_access`.
