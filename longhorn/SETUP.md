## Prerequisites

Ensure each node has:
- open-iscsi or iscsiadm installed

## Installation

Install open-iscsi on each node:

```bash
sudo apt-get install -y open-iscsi
sudo systemctl enable --now iscsid
```

## Deploy

```bash
./deploy.sh
```

## Configuration

- **Default StorageClass**: longhorn (2 replicas)
- **Data locality**: best-effort (prefers local replicas)
- **Storage path**: /var/lib/longhorn/ on each node
- **Over-provisioning**: 200%
- **UI**: Disabled (use kubectl to manage)

## Notes

```bash
# Get all volumes
kubectl get volumes.longhorn.io -n longhorn-system 

# Delete orphaned volumes
kubectl get volumes.longhorn.io -n longhorn-system -o json | jq -r '.items[] | select(.status.state == "detached") | .metadata.name' | tr -d '\r' | xargs kubectl delete volume.longhorn.io -n longhorn-system
```