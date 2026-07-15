## system-upgrade-controller

Keeps k3s itself on the latest stable release automatically, one node at a time, control plane first.

[k3s automated upgrades](https://docs.k3s.io/upgrades/automated)

## How it works

1. The controller watches the k3s `stable` release channel for a new version
2. When the channel moves, `server-plan` cordons each control-plane node, upgrades k3s, and uncordons it
3. `agent-plan` waits for `server-plan` to finish (its `prepare` step), then drains, upgrades, and uncordons each worker
4. `concurrency: 1` on both plans means only one node per plan is touched at a time

Node upgrades run as Jobs in the `system-upgrade` namespace as soon as a new version lands, not on a schedule.

## Relationship to kured

[kured](../kured/SETUP.md) reboots nodes for OS updates; this reboots nothing but restarts k3s for version updates. They solve different problems and do not share a lock, so both can drain a node at the same time. Worth watching on a small cluster — if it becomes a problem, pin `channel` to a specific `version` and apply upgrades deliberately.

## Deploy

```bash
cd system-upgrade-controller
bash deploy.sh
```

The manifests create the `system-upgrade` namespace and its service account, so this needs no entry in `namespaces.sh`.

## Verify

```bash
kubectl get plans -n system-upgrade
kubectl get jobs -n system-upgrade
kubectl get nodes -o wide   # confirm VERSION once a plan completes
```

Watch an in-progress upgrade:

```bash
kubectl logs -n system-upgrade -l upgrade.cattle.io/controller=system-upgrade-controller -f
```

## Pinning a version

`channel` tracks stable. To control the target explicitly, swap it for a version in `plans.yaml` (both plans):

```yaml
  version: v1.36.2+k3s1
```

## Uninstall

```bash
kubectl delete -f plans.yaml
kubectl delete namespace system-upgrade
```
