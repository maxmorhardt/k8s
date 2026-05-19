# Self-Hosted Kubernetes Stack

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Tailscale](https://img.shields.io/badge/tailscale-242424?style=for-the-badge&logo=tailscale&logoColor=white)
![Authentik](https://img.shields.io/badge/Authentik-FD4B2D?style=for-the-badge&logo=authentik&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)
![NATS](https://img.shields.io/badge/nats-27AAE1?style=for-the-badge&logo=nats.io&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Alertmanager](https://img.shields.io/badge/Alertmanager-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white)
![Loki](https://img.shields.io/badge/loki-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Alloy](https://img.shields.io/badge/alloy-00D4AA?style=for-the-badge&logo=grafana&logoColor=white)
![kured](https://img.shields.io/badge/kured-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)

## Overview
A comprehensive self-hosted Kubernetes (K3s) infrastructure stack with production-ready services for container orchestration, access management, authentication, data persistence, CI/CD, monitoring, and logging. Designed for on-premises deployment with high availability.

## Features
- **Container Orchestration** with Kubernetes (K3s)
- **Persistent Storage** with local-path-retain StorageClass (Retain reclaim policy)
- **Authentication & Authorization** via Authentik OIDC/SAML provider
- **Data Persistence** with PostgreSQL HA cluster and NATS messaging
- **CI/CD Pipeline** using GitHub Actions with shared reusable workflows
- **Monitoring & Observability** with Prometheus, Grafana dashboards, and Alertmanager (Discord + email alerts, healthchecks.io dead-man's switch)
- **Centralized Logging** via Loki and Alloy data collection
- **Automated Node Maintenance** with kured — weekly coordinated reboots with pre-reboot cleanup (apt upgrade, image prune, log rotation)
- **Production Ready** with resource limits, application-level replication, and security configurations

## Architecture
The stack follows a microservices architecture where each service is independently deployable with Helm charts. Services communicate through Kubernetes networking, with Authentik providing centralized authentication for applications requiring OIDC/SAML. CI/CD is handled via GitHub Actions.

```
      ┌──────────────┐    ┌──────────────┐
      │  Kubernetes  │◀───│GitHub Actions│
      │    (K3s)     │    │   (CI/CD)    │
      └──────────────┘    └──────────────┘
                        │
       ┌────────────────┼────────────────┐
       │                │                │
  ┌────▼─────┐    ┌─────▼──────┐    ┌───▼────┐
  │Authentik │    │Prometheus/ │    │ Loki/  │
  │  (Auth)  │    │ Grafana    │    │ Alloy  │
  └──────────┘    │(Monitoring)│    │(Logs)  │
                  └────────────┘    └────────┘
       ┌──────────────┼──────────────┐
       │              │              │
  ┌────▼─────┐   ┌────▼─────┐   ┌───▼────┐
  │PostgreSQL│   │   NATS   │   │ Apps   │
  │   (DB)   │   │(Messaging│   │        │
  └──────────┘   │ Pub/Sub) │   └────────┘
                 └──────────┘
```

## Deployment Order

1. **Core Infrastructure**: K3s cluster with Tailscale on nodes
2. **Storage Layer**: `kubectl apply -f storage/local-path-retain.yaml`
3. **Database Layer**: Postgres
4. **Access & Visualization**: Kube Prometheus Stack
5. **Core Services**: NATS, Loki, Alloy
6. **Authentication**: Authentik
7. **Node Maintenance**: kured

**Note:** Redeploys will be required if apps are installed prior to Prometheus CRDs

### CI/CD
CI/CD pipelines are managed via GitHub Actions using a shared reusable workflow at `maxmorhardt/workflows`. Workflows deploy services to the cluster over Tailscale.

### Node Maintenance
kured (Kubernetes Reboot Daemon) runs as a DaemonSet on all nodes including control plane. On Tuesdays at 02:00 it checks for `/var/run/reboot-required` and coordinates rolling reboots — only one node at a time. Before each reboot, `pre-reboot.sh` runs on the host to:
- Prune unused container images
- Run `apt upgrade` and autoremove
- Vacuum systemd journal (7 day retention)
- Delete log files older than 30 days
- Clear `/tmp` and `/var/tmp`

Logs are written to `/var/log/kured` on each node. Reboot notifications are sent to Discord.
