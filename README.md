# Kubernetes
This repo contains all instructions and files for self hosted kubernetes (k3s) and some additional resources/applications.

## Instructions
Each directory contains instructions or a deploy script for a given resource. Some scripts contains environment variables which will be specific to a given kubernetes setup. Naming a file '*-with-secrets*' allows users to give their environment specific setup without exposing secrets or any information to Git/VCS.

## Resource Dependencies
A given resource might require one or more resources to be deployed prior. For example, Jenkins requires an OIDC provider (Keycloak in my case) to be deployed in order to authenticate and authorize users.