helm repo add grafana https://grafana.github.io/helm-charts 
helm repo update

helm upgrade grafana grafana/grafana \
	--values values.yaml \
	--install \
  --rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace monitoring