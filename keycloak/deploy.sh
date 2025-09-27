#!/bin/bash

export KEYCLOAK_ADMIN_USERNAME_B64=""
export KEYCLOAK_ADMIN_PASSWORD_B64=""
export KEYCLOAK_DB_USERNAME_B64=""
export KEYCLOAK_DB_PASSWORD_B64=""
export KEYCLOAK_DB_HOST_B64=""
export KEYCLOAK_CERT_B64=""
export KEYCLOAK_CERT_PRIVATE_KEY_B64=""
export CA_CERT_PATH=""
export CA_CERT_PRIVATE_KEY_PATH=""

if [[ -z "$KEYCLOAK_ADMIN_USERNAME_B64" || 
	  -z "$KEYCLOAK_ADMIN_PASSWORD_B64" || 
	  -z "$KEYCLOAK_DB_USERNAME_B64" || 
	  -z "$KEYCLOAK_DB_PASSWORD_B64" || 
	  -z "$KEYCLOAK_DB_HOST_B64" || 
	  -z "$KEYCLOAK_CERT_B64" || 
	  -z "$KEYCLOAK_CERT_PRIVATE_KEY_B64" || 
	  -z "$CA_CERT_PATH" || 
	  -z "$CA_CERT_PRIVATE_KEY_PATH" 
]]; then
	echo "ERROR: Environment variables not set"
	exit 1
fi

set -x
							
sed -i "s/<KEYCLOAK_ADMIN_USERNAME>/$KEYCLOAK_ADMIN_USERNAME_B64/g" secret.yaml
sed -i "s/<KEYCLOAK_ADMIN_PASSWORD>/$KEYCLOAK_ADMIN_PASSWORD_B64/g" secret.yaml
sed -i "s/<KEYCLOAK_DB_USERNAME>/$KEYCLOAK_DB_USERNAME_B64/g" secret.yaml
sed -i "s/<KEYCLOAK_DB_PASSWORD>/$KEYCLOAK_DB_PASSWORD_B64/g" secret.yaml
sed -i "s/<KEYCLOAK_DB_HOST>/$KEYCLOAK_DB_HOST_B64/g" secret.yaml
sed -i "s/<KEYCLOAK_CERT>/$KEYCLOAK_CERT_B64/g" secret.yaml
sed -i "s/<KEYCLOAK_CERT_PRIVATE_KEY>/$KEYCLOAK_CERT_PRIVATE_KEY_B64/g" secret.yaml

cat secret.yaml

cp $CA_CERT_PATH .
cp $CA_CERT_PRIVATE_KEY_PATH .

echo "$DOCKER_PASSWORD" | helm registry login registry-1.docker.io --username $DOCKER_USERNAME --password-stdin

helm package helm

kubectl delete secret auth.maxstash.io-tls --namespace maxstash-global
kubectl create secret tls auth.maxstash.io-tls --cert=cert.pem --key=key.pem --namespace maxstash-global

rm cert.pem
rm key.pem

kubectl apply --filename secret.yaml --namespace maxstash-global

helm upgrade keycloak keycloak-1.0.0.tgz --install --atomic --debug --history-max=3 --namespace maxstash-global --timeout 15m0s

rm keycloak-1.0.0.tgz

git restore secret.yaml