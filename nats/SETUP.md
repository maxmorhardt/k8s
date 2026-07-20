## Overview

NATS pub/sub in the `nats` namespace. Backs cross-instance WebSocket fan-out for the APIs, so
an event published by one replica reaches clients connected to any other.

## Access

- Client: `nats.nats.svc.cluster.local:4222`
- Monitoring: `http://nats.nats.svc.cluster.local:8222`
- Prometheus metrics: `http://nats.nats.svc.cluster.local:7777/metrics`

## Notes

- `make nats` in the API repos port-forwards a local connection for development.
