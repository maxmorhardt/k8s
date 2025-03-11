![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Rancher](https://img.shields.io/badge/Rancher-0075A8?style=for-the-badge&logo=rancher)
![Keycloak](https://img.shields.io/badge/Keycloak-blue?style=for-the-badge&logo=keycloak)
![Postgres](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)

## Overview
This repo contains all instructions and files for self hosted kubernetes (k3s) and some additional resources/applications.

## Instructions
Each directory contains instructions and/or a deploy script for a given resource. Some scripts contains environment variables which will be specific to a given kubernetes setup. Naming a file '*-with-secrets*' allows users to give their environment specific setup without exposing secrets or any information to Git/VCS.

## Resource Dependencies
A given resource might require one or more resources to be deployed prior. For example, Jenkins requires an OIDC provider (Keycloak in my case) to be deployed in order to authenticate and authorize users.