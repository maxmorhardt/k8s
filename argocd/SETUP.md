## Overview

GitOps control plane at `argocd.maxstash.io`. Every workload is an `Application` reconciled
from this repo — CI holds no kubeconfig, it builds an artifact and commits a version here.

```
argocd/
  bootstrap.sh   installs and repairs Argo itself
  values.yaml    argo-cd chart values (excluded from root's scan)
  root.yaml      app-of-apps, recurses over this directory
  infra/         one Application per infra component, incl. argocd
  apps/          one Application per application chart
```

Adding anything is a new file in `infra/` or `apps/`; root picks it up within 3 minutes. Any
other non-Application yaml under `argocd/` **will** be applied to the cluster.

## Applications

**Infra** charts are upstream; values stay at `<component>/values.yaml`. Each uses two sources
— the chart, plus this repo as `ref: values` — so `valueFiles` can reference
`$values/dex/values.yaml`. Versions carry `# renovate:` comments, so merging the PR is the deploy.

**Apps** come from `ghcr.io/maxmorhardt/charts`, with chart version and image tag pinned
exactly and committed by CI once the artifact exists:

```
app repo    tag 1.3.2         → publishes image     → commits image.tag
charts repo tag squares/1.0.2 → publishes OCI chart → commits targetRevision
```

Ranges are avoided deliberately — they roll out with nothing in git recording what is deployed.
Secrets are sealed in [secrets/](../secrets/), synced by [infra/secrets.yaml](infra/secrets.yaml).

## Bootstrap

Argo cannot deploy itself, so [bootstrap.sh](bootstrap.sh) runs by hand; re-running it repairs
Argo.

```bash
cd argocd && ./bootstrap.sh
```

Argo **adopts** what is already running rather than redeploying it, so never `helm uninstall`
first — that deletes live resources. Helm's `managed-by` labels show as diff noise and settle
after the first sync.

The CLI needs a session: port-forward and `argocd login localhost:8080` before SSO exists, or
`argocd login argocd.maxstash.io --grpc-web` through the gateway.

## SSO

Argo federates to the cluster's own [Dex](../dex/SETUP.md), so the bundled dex stays off. Two
clients in [dex/values.yaml](../dex/values.yaml): `argocd` for the UI, public `argocd-cli` for
`argocd login --sso`. Identity is the verified **email** claim — this Dex has no groups, so
`rbac.scopes` is `[email]`; the chart default `[groups]` would never resolve. Everyone gets
`role:readonly`, admin is per email in `policy.csv`.

The secret must exist on both sides — `ARGOCD_CLIENT_SECRET` in Dex's `dex-env`, and sealed
here. The `part-of` label is required or Argo cannot resolve the `$argocd-oidc:` reference:

```bash
kubectl create secret generic argocd-oidc --namespace argocd \
  --from-literal=clientSecret="$(openssl rand -hex 32)" --dry-run=client -o yaml \
| kubectl label --local -f - app.kubernetes.io/part-of=argocd -o yaml \
| kubeseal --format yaml --cert sealed-secrets/pub-cert.pem > secrets/argocd/argocd-oidc.yaml
```

## Notes

- **Deploy**: cut a release. **Roll back**: revert the commit — `selfHeal` makes cluster-side
  rollbacks transient. **Pause**: drop `syncPolicy.automated`.
- **Argo down**: workloads keep running, only new deploys stall.
- `prune: false` on `postgres-cluster`, `storage`, `maxstash-gateway` — pruning those on a bad
  manifest would be destructive.
- Single replicas throughout. `applicationSet.replicas: 0` because chart 10.x has no `enabled`
  key and silently ships the controller otherwise.
- CI needs `GITOPS_TOKEN` with `contents: write` here, and branch protection must allow it.
