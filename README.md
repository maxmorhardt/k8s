# Self-Hosted Kubernetes Stack

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Rancher](https://img.shields.io/badge/Rancher-0075A8?style=for-the-badge&logo=rancher)
![Zitadel](https://img.shields.io/badge/Zitadel-6C5CE7?style=for-the-badge&logo=zitadel&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Jenkins](https://img.shields.io/badge/jenkins-D24939?style=for-the-badge&logo=jenkins&logoColor=black)
![Redis](https://img.shields.io/badge/redis-%23DD0031.svg?style=for-the-badge&logo=redis&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white)
![Loki](https://img.shields.io/badge/loki-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Alloy](https://img.shields.io/badge/alloy-00D4AA?style=for-the-badge&logo=grafana&logoColor=white)

## Overview
A comprehensive self-hosted Kubernetes (K3s) infrastructure stack with production-ready services for container orchestration, authentication, data persistence, CI/CD, monitoring, and logging. Designed for on-premises deployment with minimal external dependencies.

## Features
- **Container Orchestration** with Kubernetes (K3s) and Rancher management
- **Authentication & Authorization** via Zitadel OIDC provider
- **Data Persistence** with PostgreSQL database and Redis caching/pub-sub
- **CI/CD Pipeline** using Jenkins with OIDC integration
- **Monitoring & Observability** with Prometheus metrics and Grafana dashboards
- **Centralized Logging** via Loki and Alloy data collection
- **Production Ready** with persistent storage, resource limits, and security configurations

## Architecture
The stack follows a microservices architecture where each service is independently deployable with Helm charts. Services communicate through Kubernetes networking, with Zitadel providing centralized authentication for Jenkins and other applications requiring OIDC.

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Rancher   │───▶│  Kubernetes  │◀───│   Jenkins   │
│ (Management)│    │    (K3s)     │    │   (CI/CD)   │
└─────────────┘    └──────┬───────┘    └─────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
    ┌────▼─────┐    ┌─────▼──────┐    ┌───▼────┐
    │ Zitadel  │    │Prometheus/ │    │ Loki/  │
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

## Services

| Service | Purpose | Port | Namespace | Dependencies |
|---------|---------|------|-----------|--------------|
| **Rancher** | Kubernetes cluster management | 80/443 | cattle-system | None |
| **Zitadel** | OIDC authentication provider | 8080 | zitadel | PostgreSQL |
| **Jenkins** | CI/CD automation server | 8080 | jenkins | Zitadel |
| **PostgreSQL** | Primary database | 5432 | db | None |
| **Redis** | Caching & pub/sub messaging | 6379 | db | None |
| **Prometheus** | Metrics collection | 9090 | monitoring | None |
| **Grafana** | Metrics visualization | 3000 | monitoring | Prometheus |
| **Loki** | Log aggregation | 3100 | monitoring | None |
| **Alloy** | Telemetry data collection | 12345 | monitoring | Prometheus, Loki |

## Deployment Order

1. **Core Infrastructure**: K3s cluster setup
2. **Storage**: PostgreSQL, Redis
3. **Authentication**: Zitadel (requires PostgreSQL)
4. **CI/CD**: Jenkins (requires Zitadel)
5. **Monitoring**: Prometheus, Grafana, Loki, Alloy
6. **Management**: Rancher

## Development

Each service directory contains:
- **SETUP.md** - Service-specific setup instructions and required secrets
- **values.yaml** - Helm chart configuration
- **deploy.sh** - Deployment script using helm upgrade
- **Jenkinsfile** - CI/CD pipeline for automated deployment
- **storage.yaml** - Persistent volume configurations (where applicable)

### Secret Management
All secrets are managed via Kubernetes secrets and mounted as environment variables. See each service's SETUP.md for required secret keys and example YAML format.

### Node Maintenance
Weekly automated node rehydration runs on Sunday mornings (staggered 2-5 AM) via cron:
- Drains node
- Updates system packages
- Cleans up container images, logs, and temp files
- Logs to `/var/log/rehydrate/` (collected by Alloy)

## Resource Dependencies

Services have the following dependency chain:
- **Jenkins** → requires Keycloak (OIDC), has cluster-admin permissions for CI/CD
- **Keycloak** → requires PostgreSQL (database)
- **Grafana** → requires Prometheus (data source), Keycloak (OIDC)
- **Alloy** → requires Loki (log target)
- **Rancher** → requires Keycloak (OIDC)

Deploy dependencies first to avoid service startup issues.

## Node Assignments
- **main**: Control plane, Alloy
- **max-worker**: PostgreSQL, Prometheus, Grafana
- **max-worker-2**: Jenkins
- **max-worker-3**: Redis, Loki