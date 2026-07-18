helm repo add grafana https://grafana.github.io/helm-charts 
helm repo update

# renovate: datasource=helm depName=alloy registryUrl=https://grafana.github.io/helm-charts
helm upgrade alloy grafana/alloy \
  --version 1.10.1 \
  --values values.yaml \
  --install \
  --rollback-on-failure \
	--wait \
  --debug \
  --history-max=3 \
  --namespace monitoring