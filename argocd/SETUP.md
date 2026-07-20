## Applications

**Infra** charts are upstream; their values stay at `<component>/values.yaml`. Each uses two
sources — the chart, plus this repo as `ref: values` — so `valueFiles` can reference
`$values/dex/values.yaml`. Versions carry `# renovate:` comments, so merging the PR is the
deploy.

**Apps** come from `ghcr.io/maxmorhardt/charts`, with both `targetRevision` and
`helm.parameters[image.tag]` pinned exactly and committed by CI — the app repo commits the
image tag, the charts repo commits the chart version. Each `deploy` job `needs:` its publish
job, so a version is only committed once the artifact exists. Ranges are avoided deliberately — they roll out with nothing in git recording what is
deployed and no commit to revert.

Secrets are sealed in [secrets/](../secrets/), synced by [infra/secrets.yaml](infra/secrets.yaml).

## Bootstrap

Argo cannot deploy itself, so [bootstrap.sh](bootstrap.sh) runs by hand; re-running it repairs
Argo. The first cutover must be a **no-op** — Argo adopts what is already running. Do not
`helm uninstall` anything first, that deletes live resources.

```bash
cd argocd && ./bootstrap.sh                   # install, nothing syncs yet

for f in infra/*.yaml apps/*.yaml; do         # create with sync disabled
  yq 'del(.spec.syncPolicy.automated)' "$f" | kubectl apply -f -
done

for f in infra/*.yaml apps/*.yaml; do         # expect empty diffs
  argocd app diff "$(basename "$f" .yaml)" || true
done

./bootstrap.sh --apply-root                   # hand over
```

A non-empty diff means the manifest does not match reality — fix the manifest, not the
cluster. Helm's `managed-by` labels show as noise and settle after the first sync. The CLI
needs a session first: port-forward and `argocd login localhost:8080` before SSO exists, or
`argocd login argocd.maxstash.io --grpc-web` through the gateway.

## SSO

Argo federates to the cluster's own [Dex](../dex/SETUP.md), so the bundled dex stays off.
Two clients in [dex/values.yaml](../dex/values.yaml): `argocd` for the UI, public
`argocd-cli` for `argocd login --sso`. Identity is the verified **email** claim — this Dex has
no groups, so `rbac.scopes` is `[email]`; the chart default `[groups]` would never resolve.
Everyone gets `role:readonly`, admin is per email in `policy.csv`.

The client secret must exist on both sides — `ARGOCD_CLIENT_SECRET` in Dex's `dex-env`, and
sealed here. The `part-of` label is required or Argo cannot resolve the `$argocd-oidc:` ref:

```bash
secret=$(openssl rand -hex 32)

kubectl create secret generic argocd-oidc --namespace argocd \
  --from-literal=clientSecret="$secret" --dry-run=client -o yaml \
| kubectl label --local -f - app.kubernetes.io/part-of=argocd -o yaml \
| kubeseal --format yaml --cert sealed-secrets/pub-cert.pem \
  > secrets/argocd/argocd-oidc.yaml
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
