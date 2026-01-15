# Setup

## Architecture
- **1 Master** - Handles writes and reads

## Configuration
- **Storage**: 1Gi
- **Auth**: Disabled (internal cluster use only)

## Access
- Service: `redis-master.redis.svc.cluster.local:6379`

## Deployment
```bash
./deploy.sh
```
