## Overview

Encrypts secrets so they can live in git. A `SealedSecret` is encrypted with a public key;
only the controller holds the private half and unseals it into a real `Secret`. Sealed
manifests live in [secrets/](../secrets/), applied by their own Application.

The [sealed-secrets Application](../argocd/infra/sealed-secrets.yaml) carries `sync-wave: -1`
so the CRD exists before anything tries to create a `SealedSecret`.

## Setup

1. `brew install kubeseal` (or grab the release binary)
2. **Back up the sealing key — before sealing anything.** See below.
3. Export the public cert so sealing works without cluster access. It is public and committed
   on purpose:
   ```bash
   kubeseal --controller-name sealed-secrets --controller-namespace sealed-secrets \
     --fetch-cert > sealed-secrets/pub-cert.pem
   ```

## Sealing

```bash
# from a scratch file (never commit the plaintext)
kubeseal --format yaml --cert sealed-secrets/pub-cert.pem \
  < secret.yaml > secrets/<namespace>/<name>.yaml && rm secret.yaml

# or from a secret already in the cluster
kubectl get secret dex-env -n dex -o yaml \
  | kubeseal --format yaml --cert sealed-secrets/pub-cert.pem > secrets/dex/dex-env.yaml
```

Changing one key means re-sealing the whole secret — there is no partial edit, and you cannot
read the plaintext back out of git. Keep it in a password manager.

To adopt a `Secret` the controller did not create, annotate it first or the sync fails with
*"already exists and is not managed by SealedSecret"*:

```bash
kubectl annotate secret <name> -n <namespace> sealedsecrets.bitnami.com/managed=true
```

## Backing up the sealing key

Lose the private key and **every sealed manifest in this repo becomes permanently
undecryptable** — the only recovery is reissuing each secret from upstream.

```bash
kubectl get secret -n sealed-secrets \
  -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-key.yaml
```

Store it outside the cluster and outside this repo; `sealed-secrets-key*.yaml` is gitignored.
To restore onto a rebuilt cluster, apply it **before** the controller starts, then restart it:

```bash
kubectl apply -f sealed-secrets-key.yaml
kubectl rollout restart deploy/sealed-secrets -n sealed-secrets
```

Rotation is disabled (`keyrenewperiod: '0'`). The default 30-day rotation quietly makes the
backup stale — one file, backed up once, is the safer trade.

## Notes

- Strict-scoped: ciphertext is bound to both namespace and name. Renaming or moving a secret
  requires re-sealing.
- Only values are encrypted — key names stay readable in git.
- The [secrets Application](../argocd/infra/secrets.yaml) runs `prune: false`; pruning a live
  `SealedSecret` would garbage-collect the `Secret` it owns and take the app down.
- `selfHeal` reverts hand-edits to an unsealed `Secret` on the next reconcile.
- Still to migrate: `dex-env`, `postgres-superuser`, `postgres-admin-user`, `aws-s3-credentials`.
