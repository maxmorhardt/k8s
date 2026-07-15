[k3s automated upgrades](https://docs.k3s.io/upgrades/automated)

## Schedule

Both plans only create upgrade jobs Wednesday 02:00–04:00 America/New_York

## Deploy

Run the [system-upgrade-controller CD](../.github/workflows/cd-system-upgrade-controller.yml) workflow, or locally:

```bash
cd system-upgrade-controller
bash deploy.sh
```

## Verify

```bash
kubectl get plans -n system-upgrade
kubectl get jobs -n system-upgrade
kubectl get nodes -o wide
```