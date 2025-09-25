#!/bin/bash

export POSTGRES_ADMIN_PASSWORD_B64=""
export POSTGRES_USER_PASSWORD_B64=""

if [[ -z "$POSTGRES_ADMIN_PASSWORD_B64" || -z "$POSTGRES_USER_PASSWORD_B64" ]]; then
	echo "ERROR: Environment variables not set"
	exit 1
fi

set -x

sed -i "s/<POSTGRES_ADMIN_PASSWORD>/$POSTGRES_ADMIN_PASSWORD_B64/g" secret.yaml
sed -i "s/<POSTGRES_USER_PASSWORD>/$POSTGRES_USER_PASSWORD_B64/g" secret.yaml

cat secret.yaml

kubectl apply --filename storage.yaml --namespace maxstash-global
kubectl apply --filename secret.yaml --namespace maxstash-global

helm install db oci://registry-1.docker.io/bitnamicharts/postgresql --version 16.7.27 --values values.yaml --namespace maxstash-global

git restore secret.yaml