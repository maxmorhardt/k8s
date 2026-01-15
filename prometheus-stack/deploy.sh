#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: ./deploy.sh <discord-webhook-url>"
  exit 1
fi

DISCORD_WEBHOOK="$1"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
	--values values.yaml \
	--set alertmanager.config.receivers[2].discord_configs[0].webhook_url="$DISCORD_WEBHOOK" \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace monitoring \
	--create-namespace