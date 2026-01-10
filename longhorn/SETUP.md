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
