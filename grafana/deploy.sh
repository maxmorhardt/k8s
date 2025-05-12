export GRAFANA_CLIENT_ID=""
export GRAFANA_CLIENT_SECRET=""
export CA_CERT_PATH=""
export CA_CERT_PRIVATE_KEY_PATH=""
export GRAFANA_ADMIN_USER_B64=""
export GRAFANA_ADMIN_PASSWORD_B64=""

if [[ -z "$GRAFANA_CLIENT_ID" || -z "$GRAFANA_CLIENT_SECRET" || -z "$CA_CERT_PATH" || -z "$CA_CERT_PRIVATE_KEY_PATH" ]]; then
	echo "ERROR: Environment variables not set"
	exit 1
fi

sed -i "s/<GRAFANA_CLIENT_ID>/$GRAFANA_CLIENT_ID/g" values.yaml
sed -i "s/<GRAFANA_CLIENT_SECRET>/$GRAFANA_CLIENT_SECRET/g" values.yaml

sed -i "s/<GRAFANA_ADMIN_USER>/$GRAFANA_ADMIN_USER_B64/g" secret.yaml
sed -i "s/<POSTGRES_USER_PASSWORD>/$GRAFANA_ADMIN_PASSWORD_B64/g" secret.yaml

cp $CA_CERT_PATH .
cp $CA_CERT_PRIVATE_KEY_PATH .

kubectl delete secret grafana.maxstash.io-tls --namespace maxstash-global
kubectl create secret tls grafana.maxstash.io-tls --cert=cert.pem --key=key.pem --namespace maxstash-global

rm cert.pem
rm key.pem

kubectl apply -f secret.yaml -n maxstash-global

helm repo add grafana https://grafana.github.io/helm-charts 
helm repo update
helm upgrade grafana grafana/grafana --values values.yaml --install --atomic --debug --history-max=3 --namespace maxstash-global

git restore values.yaml
git restore secret.yaml