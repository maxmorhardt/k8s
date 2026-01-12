# Redis Setup

## Overview
Redis deployment with Sentinel for high availability and automatic failover.

## Architecture
- **1 Master** - Handles writes and reads
- **1 Replica** - Read replica, promoted to master during failover
- **Sentinel** - Monitors cluster health and manages automatic failover
- **Metrics** - Prometheus ServiceMonitor enabled

## Configuration
- **Storage**: 8Gi per instance using Longhorn
- **Auth**: Disabled (internal cluster use only)
- **Quorum**: 2 (both Sentinels must agree on failover)

## Access
- Service: `redis.redis.svc.cluster.local:6379`
- Sentinel: `redis.redis.svc.cluster.local:26379`

## Deployment
```bash
./deploy.sh
```
