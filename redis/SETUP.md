## Storage
1. SSH into node that will host Redis (max-worker-3)
2. Create directory /bitnami/redis with 1001:1001 owner/group
   ```bash
   sudo mkdir -p /bitnami/redis
   sudo chown -R 1001:1001 /bitnami/redis
   ```