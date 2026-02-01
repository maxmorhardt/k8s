helm repo add authentik https://charts.goauthentik.io
helm repo update

helm upgrade authentik authentik/authentik \
	--version 2025.12.2 \
	--install \
  --rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace authentik \
	--timeout 15m \
	--values values.yaml