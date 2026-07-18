helm repo add grafana https://grafana.github.io/helm-charts 
helm repo update

# renovate: datasource=helm depName=loki registryUrl=https://grafana.github.io/helm-charts
helm upgrade loki grafana/loki \
	--version 7.1.0 \
	--values values.yaml \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace monitoring