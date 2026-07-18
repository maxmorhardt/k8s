#!/bin/bash

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# renovate: datasource=helm depName=kube-prometheus-stack registryUrl=https://prometheus-community.github.io/helm-charts
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
	--version 87.17.0 \
	--values values.yaml \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace monitoring \
	--create-namespace