helm repo add authentik https://charts.goauthentik.io
helm repo update

helm upgrade authentik authentik/authentik \
	--install \
	--atomic \
	--debug \
	--history-max=3 \
	--namespace authentik \
	--timeout 15m \
	--values values.yaml
