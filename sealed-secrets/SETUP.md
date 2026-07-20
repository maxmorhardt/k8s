# Sealed Secrets

Encrypts secrets so they can live in git. A `SealedSecret` is asymmetrically encrypted
with a public key; the controller in the cluster holds the private half and unseals it
into a real `Secret`. Ciphertext is useless to anyone without that key, so this repo can
be the source of truth for secrets the same way it already is for everything else.

One Helm release in the `sealed-secrets` namespace (`sealed-secrets` from
https://bitnami.github.io/sealed-secrets), config in [values.yaml](values.yaml).
Sealed manifests live in [secrets/](../secrets/) and are applied by their own Application.

## One-time setup

1. Merge to `main` — Argo CD syncs the [sealed-secrets Application](../argocd/infra/sealed-secrets.yaml).
   It carries `sync-wave: -1` so the CRD exists before anything tries to create a `SealedSecret`.
2. Install the CLI locally: `brew install kubeseal` (or grab the release binary).
3. **Back up the sealing key** — see below. Do this before sealing anything.
4. Export the public cert so sealing works without cluster access:
   ```bash
   kubeseal --controller-name sealed-secrets --controller-namespace sealed-secrets \
     --fetch-cert > sealed-secrets/pub-cert.pem
   ```
   This is a public key and is committed on purpose.

## Sealing a secret

Write the plaintext `Secret` to a scratch file (never commit it), then seal:

```bash
kubeseal --format yaml --cert sealed-secrets/pub-cert.pem \
  < secret.yaml > secrets/<namespace>/<name>.yaml
rm secret.yaml
```

Commit the output. Argo applies it, the controller unseals it, the app sees a normal `Secret`.

To seal a secret that already exists in the cluster, read it out rather than retyping:

```bash
kubectl get secret dex-env -n dex -o yaml \
  | kubeseal --format yaml --cert sealed-secrets/pub-cert.pem \
  > secrets/dex/dex-env.yaml
```

Changing one key means re-sealing the whole secret — there is no partial edit. Keep the
plaintext somewhere you control (a password manager), because you cannot read it back out
of git.

## Backing up the sealing key

Lose the private key and **every sealed manifest in this repo becomes permanently
undecryptable**. Git history stops being a backup and the only recovery is reissuing each
secret from upstream — Google and GitHub OAuth clients, AWS credentials, Postgres passwords.

```bash
kubectl get secret -n sealed-secrets \
  -l sealedsecrets.bitnami.com/sealed-secrets-key \
  -o yaml > sealed-secrets-key.yaml
```

Store it outside the cluster and outside this repo. `sealed-secrets-key*.yaml` is
gitignored so it cannot be committed by accident.

To restore onto a rebuilt cluster, apply the backup **before** the controller starts, then
restart it so it picks the key up:

```bash
kubectl apply -f sealed-secrets-key.yaml
kubectl rollout restart deploy/sealed-secrets -n sealed-secrets
```

Key rotation is disabled (`keyrenewperiod: '0'`). The default is a fresh key every 30 days,
which quietly makes the backup stale — one file, backed up once, is the safer trade here.

## Migrating an existing secret

The controller will not take over a `Secret` it did not create. Annotate first, or the
sync fails with *"already exists and is not managed by SealedSecret"*:

```bash
kubectl annotate secret <name> -n <namespace> sealedsecrets.bitnami.com/managed=true
```

Then seal it from the live value as above and commit. The next sync adopts it in place —
no restart, no downtime for the consuming app.

Secrets to migrate: `dex-env` ([dex](../dex/SETUP.md)), and `postgres-superuser`,
`postgres-admin-user`, `aws-s3-credentials` ([postgres](../postgres/SETUP.md)).

## Notes

- Sealed secrets are **strict-scoped**: the ciphertext is bound to both namespace and
  name. Renaming a secret or moving it to another namespace requires re-sealing.
- Only values are encrypted — key names stay readable in git. Fine for
  `GOOGLE_CLIENT_SECRET`, worth remembering if a key name would itself leak something.
- The [secrets Application](../argocd/infra/secrets.yaml) runs with `prune: false`. A
  bad manifest pruning a live `SealedSecret` would garbage-collect the `Secret` it owns and
  take the consuming app down, so removals are a deliberate `kubectl delete`.
- `selfHeal` still applies: editing an unsealed `Secret` by hand is reverted on the next
  reconcile. Change the sealed manifest instead.
