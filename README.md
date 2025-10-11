# Self-Hosted Kubernetes Stack

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Rancher](https://img.shields.io/badge/Rancher-0075A8?style=for-the-badge&logo=rancher)
![Keycloak](https://img.shields.io/badge/Keycloak-blue?style=for-the-badge&logo=keycloak)
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
- **Authentication & Authorization** via Keycloak OIDC provider
- **Data Persistence** with PostgreSQL database and Redis caching/pub-sub
- **CI/CD Pipeline** using Jenkins with OIDC integration
- **Monitoring & Observability** with Prometheus metrics and Grafana dashboards
- **Centralized Logging** via Loki and Alloy data collection
- **Production Ready** with persistent storage, resource limits, and security configurations

## Architecture
The stack follows a microservices architecture where each service is independently deployable with Helm charts. Services communicate through Kubernetes networking, with Keycloak providing centralized authentication for Jenkins and other applications requiring OIDC.

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Rancher   │───▶│  Kubernetes  │◀───│   Jenkins   │
│ (Management)│    │    (K3s)     │    │   (CI/CD)   │
└─────────────┘    └──────┬───────┘    └─────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
    ┌────▼─────┐    ┌─────▼──────┐    ┌───▼────┐
    │ Keycloak │    │Prometheus/ │    │ Loki/  │
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

| Service | Purpose | Port | Dependencies |
|---------|---------|------|--------------|
| **Rancher** | Kubernetes cluster management | 80/443 | None |
| **Keycloak** | OIDC authentication provider | 8080 | PostgreSQL |
| **Jenkins** | CI/CD automation server | 8080 | Keycloak |
| **PostgreSQL** | Primary database | 5432 | None |
| **Redis** | Caching & pub/sub messaging | 6379 | None |
| **Prometheus** | Metrics collection | 9090 | None |
| **Grafana** | Metrics visualization | 3000 | Prometheus |
| **Loki** | Log aggregation | 3100 | None |
| **Alloy** | Telemetry data collection | 12345 | Prometheus, Loki |

## Deployment Order

1. **Core Infrastructure**: K3s cluster setup
2. **Storage**: PostgreSQL, Redis
3. **Authentication**: Keycloak (requires PostgreSQL)
4. **CI/CD**: Jenkins (requires Keycloak)
5. **Monitoring**: Prometheus, Grafana, Loki, Alloy
6. **Management**: Rancher

## Quick Start

1. **Set up K3s cluster**:
   ```bash
   cd k3s/
   ./SETUP.md
   ```

2. **Deploy core services**:
   ```bash
   # Deploy storage layer
   cd postgres/ && ./deploy-with-secrets.sh
   cd redis/ && ./deploy.sh
   
   # Deploy authentication
   cd keycloak/ && ./deploy-with-secrets.sh
   
   # Deploy monitoring
   cd prometheus/ && ./deploy.sh
   cd grafana/ && ./deploy-with-secrets.sh
   ```

3. **Access services**:
   ```bash
   # Port forward to access locally
   kubectl port-forward svc/redis-master 6379:6379
   ```

## Development

Each service directory contains:
- **SETUP.md** - Service-specific setup instructions
- **values.yaml** - Helm chart configuration
- **deploy.sh** - Standard deployment script
- **deploy-with-secrets.sh** - Production deployment with secrets
- **storage.yaml** - Persistent volume configurations (where applicable)

### Environment-Specific Configuration
Scripts named `*-with-secrets.sh` allow for environment-specific configurations without exposing secrets to version control. Copy and customize these for your deployment environment.

## Resource Dependencies

Services have the following dependency chain:
- **Jenkins** → requires Keycloak (OIDC)
- **Keycloak** → requires PostgreSQL (database)
- **Grafana** → requires Prometheus (data source)
- **Alloy** → requires Prometheus + Loki (targets)

Deploy dependencies first to avoid service startup issues.