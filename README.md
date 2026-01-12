# Self-Hosted Kubernetes Stack

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Tailscale](https://img.shields.io/badge/tailscale-242424?style=for-the-badge&logo=tailscale&logoColor=white)
![Authentik](https://img.shields.io/badge/Authentik-FD4B2D?style=for-the-badge&logo=authentik&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)
![Redis](https://img.shields.io/badge/redis-%23DD0031.svg?style=for-the-badge&logo=redis&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Alertmanager](https://img.shields.io/badge/Alertmanager-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white)
![Loki](https://img.shields.io/badge/loki-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Alloy](https://img.shields.io/badge/alloy-00D4AA?style=for-the-badge&logo=grafana&logoColor=white)
![Longhorn](https://img.shields.io/badge/longhorn-512DA8?style=for-the-badge&logo=rancher&logoColor=white)

## Overview
A comprehensive self-hosted Kubernetes (K3s) infrastructure stack with production-ready services for container orchestration, storage replication, access management, authentication, data persistence, CI/CD, monitoring, and logging. Designed for on-premises deployment with high availability.

## Features
- **Container Orchestration** with Kubernetes (K3s)
- **Distributed Storage** with Longhorn for replicated persistent volumes
- **Authentication & Authorization** via Authentik OIDC/SAML provider
- **Data Persistence** with PostgreSQL HA cluster and Redis caching/pub-sub
- **CI/CD Pipeline** using GitHub Actions
- **Monitoring & Observability** with Prometheus metrics and Grafana dashboards
- **Centralized Logging** via Loki and Alloy data collection
- **Production Ready** with replicated storage, resource limits, and security configurations

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
  │PostgreSQL│   │  Redis   │   │ Apps   │
  │   (DB)   │   │(Cache/   │   │        │
  └──────────┘   │ Pub/Sub) │   └────────┘
                 └──────────┘
```

## Deployment Order

1. **Core Infrastructure**: K3s cluster with Tailscale on nodes
2. **Storage Layer**: Longhorn
3. **Core Services**: Postgres Redis Loki Alloy
4. **Authentication**: Authentik
5. **Access & Visualization**: Kube Prometheus Stack 

### CI/CD
CI/CD pipelines are managed via GitHub Actions. Workflows deploy services to the cluster using kubectl/helm.

### Node Maintenance
Weekly automated node rehydration runs on **Tuesday** mornings (staggered 2-5 AM EST) via cron:
- Drains node
- Updates system packages
- Cleans up container images, logs, and temp files
- Logs to `/var/log/rehydrate/` (collected by Alloy)