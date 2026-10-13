## Overview

Valkey (the open-source, Redis-compatible fork) in the `redis` namespace, from the official
[valkey-helm](https://valkey.io/valkey-helm/) chart. One instance with append-only persistence on
a 2Gi `local-path-retain` volume.

The squares services use it for shared caches (leaderboard, stats, upcoming games), rate limits,
`Idempotency-Key` records, and token revocations. Every call **fails open**: if Redis is down the
services skip the cache, allow the request, and log a warning. A restart costs cache hits and
briefly forgets in-flight idempotency keys and revocations; accounts re-syncs revocations from
Postgres on startup.

Every key is prefixed `squares:` and has a TTL, so `maxmemory-policy volatile-lru` evicts the
least recently used keys when it reaches `maxmemory` (192mb, under the 256Mi limit).

## Access

- Client: `redis.redis.svc.cluster.local:6379`
- Metrics: `redis-metrics.redis.svc:9121` (redis_exporter, scraped by the `redis` ServiceMonitor)

## Users

ACL users are defined in [values.yaml](values.yaml); their passwords come from the `redis-users`
Secret, one key per user ([secret.example.yaml](secret.example.yaml)).

- `default` - full access. For `redis-cli` and the metrics exporter.
- `squares` - only `squares:*` keys, no `@dangerous` commands (`KEYS`, `FLUSHALL`, `CONFIG`, ...).
  The services connect with `REDIS_URL=redis://squares:<password>@redis.redis.svc:6379/0`,
  sealed in `squares-api-env`.

## Setup

1. Fill `secret.example.yaml` with two random passwords (`openssl rand -hex 32`) and seal it to
   `argocd/secrets/redis/redis-users.yaml` (see [sealed-secrets/SETUP.md](../sealed-secrets/SETUP.md)).
2. Merge; Argo creates the namespace and syncs [argocd/infra/redis.yaml](../argocd/infra/redis.yaml).
3. Put the `squares` password into `REDIS_URL` in `squares-api-env` and reseal it.

Rotating a password: update and reseal `redis-users`, restart the `redis` deployment (the init
container rebuilds the ACL file), then update `REDIS_URL` and restart the squares services.

## Operations

```bash
PASS=$(kubectl -n redis get secret redis-users -o jsonpath='{.data.default}' | base64 -d)
kubectl -n redis exec -it deploy/redis -c redis -- valkey-cli --user default --pass "$PASS"
# then: INFO memory, INFO stats, DBSIZE, SCAN 0 MATCH squares:revoked:* COUNT 100
```

- `make redis` in `apps/squares/api` port-forwards it for local development.
- Backup is not needed: everything here is derived or short-lived. Losing the volume loses
  nothing that Postgres cannot rebuild.
