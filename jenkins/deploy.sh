#!/bin/bash

# Note: PV path (/data/jenkins) must belong to 1000:1000 on node

export CA_CERT_PATH=""
export CA_CERT_PRIVATE_KEY_PATH=""

if [[ -z "$CA_CERT_PATH" || -z "$CA_CERT_PRIVATE_KEY_PATH" ]]; then
	echo "ERROR: Environment variables not set"
	exit 1
fi

set -x

kubectl create secret tls jenkins.maxstash.io-tls --cert=$CA_CERT_PATH --key=$CA_CERT_PRIVATE_KEY_PATH --namespace maxstash-global

kubectl apply --filename storage.yaml --namespace maxstash-global
kubectl apply --filename sa.yaml --namespace maxstash-global

helm repo add jenkinsci https://charts.jenkins.io
helm repo update

helm install jenkins jenkinsci/jenkins --values values.yaml --debug --history-max=3 --namespace maxstash-global --timeout 15m0s