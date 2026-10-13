## Overview

Valkey (the open-source, Redis-compatible fork) in the `redis` namespace, from the official
[valkey-helm](https://valkey.io/valkey-helm/) chart. One instance with append-only persistence on
a 2Gi `local-path-retain` volume.

The squares services keep two kinds of data here:

- **Event streams** - `squares:events:contest:<id>` (contests writes, realtime reads),
  `squares:events:games` (games writes, contests reads), and `squares:events:users` (accounts
  writes, contests reads). Each service appends through its Postgres outbox, so nothing is lost
  while Redis is down: events wait there and the relay catches up. Entries older than 7 days are
  trimmed, and a stream that gets no events for 7 days expires.
- **Short-lived state** - caches (leaderboard, stats, upcoming games), rate limits,
  `Idempotency-Key` records, and token revocations. These **fail open**: without Redis the
  services skip the cache and allow the request. Accounts rebuilds revocations from Postgres on
  every start.

While Redis is down, contests, games, and accounts keep serving (they start and stay ready
without it), but live updates stop: realtime is not ready and open streams end. Viewers reconnect
with their `Last-Event-ID` when it is back.

Every key is prefixed `squares:` and has a TTL. `maxmemory-policy volatile-ttl` evicts the keys
closest to expiring first when memory reaches `maxmemory` (384mb, under the 512Mi limit), which
are the caches, long before any stream. `appendfsync always` makes every acknowledged append
durable.

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

`scripts/seal-squares-secrets.sh` (from the repository root, with cluster access) generates both
passwords, seals `argocd/secrets/redis/redis-users.yaml`, and seals each squares service's secret
with the matching `REDIS_URL`. Commit all the files it writes together. To do it by hand instead,
fill [secret.example.yaml](secret.example.yaml) with two `openssl rand -hex 32` values and seal it
(see [sealed-secrets/SETUP.md](../sealed-secrets/SETUP.md)).

Argo creates the namespace and syncs [argocd/infra/redis.yaml](../argocd/infra/redis.yaml) once
merged; create it first (`kubectl create namespace redis`) so the sealed secret applies on the
first sync.

Rotating a password: update and reseal `redis-users`, restart the `redis` deployment (the init
container rebuilds the ACL file), then update `REDIS_URL` and restart the squares services.

## Operations

```bash
PASS=$(kubectl -n redis get secret redis-users -o jsonpath='{.data.default}' | base64 -d)
kubectl -n redis exec -it deploy/redis -c redis -- valkey-cli --user default --pass "$PASS"
# then: INFO memory, INFO stats, DBSIZE, SCAN 0 MATCH squares:revoked:* COUNT 100
```

- `make redis` in `apps/squares/api` port-forwards it for local development.
- Stream state: `XLEN squares:events:games`, `XINFO STREAM squares:events:users`. Contests'
  position in each stream is in Postgres: `SELECT * FROM contests.stream_offsets`.
- Backup is not needed. If the volume is lost: caches and rate limits refill; revocations come
  back on the next accounts restart; viewers whose `Last-Event-ID` no longer exists get a fresh
  snapshot; contests keeps reading from where it was, since new entry ids are newer than its
  saved position. Only events appended in the moment before the loss are gone, and the next
  change to the same game or profile carries the full state again.
