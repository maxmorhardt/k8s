## Overview

Valkey in the `valkey` namespace, from the official
[valkey-helm](https://valkey.io/valkey-helm/) chart. One instance with append-only persistence on
a 2Gi `local-path-retain` volume.

The squares services keep two kinds of data here:

- **Event streams** - `squares:events:contest:<id>` (contests writes, realtime reads),
  `squares:events:games` (games writes, contests reads), and `squares:events:users` (accounts
  writes, contests reads). Each service appends through its Postgres outbox, so nothing is lost
  while Valkey is down: events wait there and the relay catches up. Entries older than 7 days are
  trimmed, and a stream that gets no events for 7 days expires.
- **Short-lived state** - caches (leaderboard, stats, upcoming games), rate limits,
  `Idempotency-Key` records, and token revocations. These **fail open**: without Valkey the
  services skip the cache and allow the request. Accounts rebuilds revocations from Postgres on
  every start.

While Valkey is down, contests, games, and accounts keep serving (they start and stay ready
without it), but live updates stop: realtime is not ready and open streams end. Viewers reconnect
with their `Last-Event-ID` when it is back.

Every key is prefixed `squares:` and has a TTL. `maxmemory-policy volatile-ttl` evicts the keys
closest to expiring first when memory reaches `maxmemory` (384mb, under the 512Mi limit), which
are the caches, long before any stream. `appendfsync always` makes every acknowledged append
durable.

## Access

- Client: `valkey.valkey.svc.cluster.local:6379`
- Metrics: `valkey-metrics.valkey.svc:9121` (redis_exporter, scraped by the `valkey` ServiceMonitor)

## Users

ACL users are defined in [values.yaml](values.yaml); their passwords come from the `valkey-users`
Secret, one key per user ([secret.example.yaml](secret.example.yaml)).

- `default` - full access. For `valkey-cli` and the metrics exporter.
- `squares` - only `squares:*` keys, no `@dangerous` commands (`KEYS`, `FLUSHALL`, `CONFIG`, ...).
  The services connect with `REDIS_URL=redis://squares:<password>@valkey.valkey.svc:6379/0`,
  sealed in each `squares-<service>-env` Secret.

## Setup

`scripts/seal-squares-secrets.sh` (from the repository root, with cluster access) generates both
passwords, seals `argocd/secrets/valkey/valkey-users.yaml`, and seals each squares service's secret
with the matching `REDIS_URL`. Commit all the files it writes together. To do it by hand instead,
fill [secret.example.yaml](secret.example.yaml) with two `openssl rand -hex 32` values and seal it
(see [sealed-secrets/SETUP.md](../sealed-secrets/SETUP.md)).

Argo creates the namespace and syncs [argocd/infra/valkey.yaml](../argocd/infra/valkey.yaml) once
merged; create it first (`kubectl create namespace valkey`) so the sealed secret applies on the
first sync.

Rotating a password: update and reseal `valkey-users`, restart the `valkey` deployment (the init
container rebuilds the ACL file), then update `REDIS_URL` and restart the squares services.

## Operations

```bash
PASS=$(kubectl -n valkey get secret valkey-users -o jsonpath='{.data.default}' | base64 -d)
kubectl -n valkey exec -it deploy/valkey -c valkey -- valkey-cli --user default --pass "$PASS"
# then: INFO memory, INFO stats, DBSIZE, SCAN 0 MATCH squares:revoked:* COUNT 100
```

- `make valkey` in any squares service (`apps/squares/<service>` in maxstash) port-forwards it for local development.
- Stream state: `XLEN squares:events:games`, `XINFO STREAM squares:events:users`. Contests'
  position in each stream is in Postgres: `SELECT * FROM contests.stream_offsets`.

## Losing the volume

Short-lived state recovers by itself: caches and rate limits refill, revocations come back on the
next accounts restart, and viewers whose `Last-Event-ID` no longer exists get a fresh snapshot.

Events need a replay. The relay marks an outbox row published as soon as Valkey acknowledges the
append, so every games and users event contests had not read yet is gone with the volume, and
later events don't bring it back. Published rows stay in each outbox for 24 hours, so replay them
within that window:

1. Find where contests stopped reading. `last_id` is `<unix ms>-<seq>`:

   ```sql
   SELECT consumer, last_id FROM contests.stream_offsets;
   ```

2. Republish everything from that point, with a minute of margin, using one statement per outbox:

   ```sql
   UPDATE games.outbox SET published_at = NULL
    WHERE stream = 'games' AND published_at >= to_timestamp(<contests-games ms> / 1000.0) - interval '1 minute';
   UPDATE accounts.outbox SET published_at = NULL
    WHERE stream = 'users' AND published_at >= to_timestamp(<contests-users ms> / 1000.0) - interval '1 minute';
   ```

   If a consumer has no row, contests never read that stream; replay all of its outbox rows.

The relays append the rows again in their original order, and contests keeps reading from its
saved position, which every new entry id is past. Re-applying an event it already saw is harmless:
an older game snapshot never overwrites a newer one, and user events land in the order they
happened. Contest streams need no replay, since realtime sends viewers a fresh snapshot.

Connect with `kubectl -n cnpg-database exec -it <primary> -c postgres -- psql -d squares`, where
the primary is `kubectl -n cnpg-database get cluster postgres-cluster -o jsonpath='{.status.currentPrimary}'`.
