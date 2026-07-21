## Overview

Encrypts secrets so they can live in git. A `SealedSecret` is encrypted with a public key;
only the controller holds the private half and unseals it into a real `Secret`. Sealed
manifests live in [argocd/secrets/](../argocd/secrets/), applied by their own Application.

The [sealed-secrets Application](../argocd/infra/sealed-secrets.yaml) carries `sync-wave: -1`
so the CRD exists before anything tries to create a `SealedSecret`.

## Setup

1. Grab the release binary
2. **Back up the sealing key — before sealing anything.**
3. Export the public cert so sealing works without cluster access. It is public and committed
   on purpose:
   ```bash
   kubeseal --controller-name sealed-secrets --controller-namespace sealed-secrets \
     --fetch-cert > sealed-secrets/pub-cert.pem
   ```

### New secret
```bash
kubeseal --format yaml --cert sealed-secrets/pub-cert.pem \
  < secret.yaml > argocd/secrets/<namespace>/<name>.yaml && rm secret.yaml
```

### Existing secret
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
