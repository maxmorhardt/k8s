# Dex

OIDC identity provider at `https://login.maxstash.io`, federating **Google** and **GitHub** sign-in for all maxstash apps. Replaces Authentik.

One Helm release in the `dex` namespace: the upstream chart (`dex/dex` from https://charts.dexidp.io), config in [values.yaml](values.yaml). The chart's built-in `httpRoute` attaches `login.maxstash.io` to the `maxstash` Gateway.

## How identity works

- Google and GitHub are the only upstream registrations (real OAuth apps). Everything else — `squares`, `olympics`, `grafana` — is a `staticClients` entry in [values.yaml](values.yaml); their IDs/secrets are made up here, not issued by anyone.
- There is **no local user database** (`enablePasswordDB: false`). Users are identified by the **verified email** from their provider. Apps key users by the `email` claim.
- SPAs are `public: true` clients (PKCE, no secret) and deep-link straight to a provider with `connector_id=google|github`, so Dex's own login picker is never shown (`skipApprovalScreen: true`).
- Secrets: `$VAR` expansion in the config only works for the `storage` and `connectors` sections; static client secrets use the dedicated `secretEnv` field. All values come from the `dex-env` secret ([secret.example.yaml](secret.example.yaml)).

## One-time setup

1. **Postgres**: create the `dex` database and user on the CNPG cluster:
   ```sql
   CREATE USER dex WITH PASSWORD '...';
   CREATE DATABASE dex OWNER dex;
   ```
2. **Google OAuth client**: Google Cloud Console → APIs & Services → Credentials → Create OAuth client ID (Web application). Authorized redirect URI: `https://login.maxstash.io/callback`. Configure the consent screen (external, publish).
3. **GitHub OAuth app**: Settings → Developer settings → OAuth Apps → New. Authorization callback URL: `https://login.maxstash.io/callback`.
4. Create the secret: `cp secret.example.yaml secret.yaml`, fill it in, `kubectl apply -f secret.yaml` (do not commit `secret.yaml`).
5. Deploy: `./deploy.sh` (or the Dex CD workflow).

## Adding a new app

1. Add a `staticClients` entry: SPAs get `public: true` + exact redirect URIs; server-side apps get `secretEnv: <APP>_CLIENT_SECRET` plus a new key in `dex-env` (`openssl rand -hex 32`).
2. Redeploy dex. The app's OIDC config: issuer `https://login.maxstash.io`, its client id, scopes `openid profile email offline_access`.

## Notes

- **GitHub email caveat**: the connector uses the user's primary verified GitHub email. Users with no verified email cannot sign in — this is intentional (email is the identity key across providers).
- **Account linking**: the same verified email via Google and GitHub is the same user from the apps' perspective (apps upsert by email). Dex itself tracks them as separate connector identities; that's fine.
- Refresh tokens (`offline_access`) are persisted in Postgres, so they survive Dex restarts and work across both replicas.
