#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm upgrade argocd argo/argo-cd \
	--install \
	--wait \
	--timeout 10m \
	--namespace argocd \
	--create-namespace \
	--values values.yaml

kubectl apply -f root.yaml

echo
echo "admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo
