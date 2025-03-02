#!/bin/bash

# Note: PV path (/data/jenkins) must belong to 1000:1000 on node

export JENKINS_ADMIN_USERNAME=""
export JENKINS_ADMIN_PASSWORD=""
export JENKINS_CLIENT_ID=""
export JENKINS_CLIENT_SECRET=""
export CA_CERT_PATH=""
export CA_CERT_PRIVATE_KEY_PATH=""

if [[ -z "$JENKINS_ADMIN_USERNAME" || -z "$JENKINS_ADMIN_PASSWORD" || -z "$JENKINS_CLIENT_ID" || -z "$JENKINS_CLIENT_SECRET" || -z "$CA_CERT_PATH" || -z "$CA_CERT_PRIVATE_KEY_PATH" ]]; then
	echo "ERROR: Environment variables not set"
	exit 1
fi

set -x

sed -i "s/<JENKINS_ADMIN_USERNAME>/$JENKINS_ADMIN_USERNAME/g" values.yaml
sed -i "s/<JENKINS_ADMIN_PASSWORD>/$JENKINS_ADMIN_PASSWORD/g" values.yaml
sed -i "s/<JENKINS_CLIENT_ID>/$JENKINS_CLIENT_ID/g" values.yaml
sed -i "s/<JENKINS_CLIENT_SECRET>/$JENKINS_CLIENT_SECRET/g" values.yaml

cat values.yaml

cp $CA_CERT_PATH .
cp $CA_CERT_PRIVATE_KEY_PATH .

kubectl delete secret jenkins.maxstash.io-tls --namespace maxstash-global
kubectl create secret tls jenkins.maxstash.io-tls --cert=cert.pem --key=key.pem --namespace maxstash-global

rm cert.pem
rm key.pem

helm uninstall jenkins --namespace maxstash-global

kubectl delete pv jenkins

kubectl apply --filename storage.yaml --namespace maxstash-global
kubectl apply --filename sa.yaml --namespace maxstash-global

helm repo add jenkinsci https://charts.jenkins.io
helm repo update

helm upgrade jenkins jenkinsci/jenkins --values values.yaml --install --atomic --debug --history-max=3 --namespace maxstash-global --timeout 15m0s

git restore values.yaml