[k3s automated upgrades](https://docs.k3s.io/upgrades/automated)

## Schedule

Both plans only create upgrade jobs Wednesday 02:00–04:00 America/New_York

## Deploy

Argo CD syncs the [system-upgrade-controller Application](../argocd/system-upgrade-controller.yaml), which builds [kustomization.yaml](kustomization.yaml) — the upstream CRDs and controller manifests plus [plans.yaml](plans.yaml).

## Verify

```bash
kubectl get plans -n system-upgrade
kubectl get jobs -n system-upgrade
kubectl get nodes -o wide
```