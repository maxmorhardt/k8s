helm repo add grafana https://grafana.github.io/helm-charts 
helm repo update

helm upgrade grafana grafana/grafana \
	--values values.yaml \
	--install \
	--atomic \
	--debug \
	--history-max=3 \
	--namespace maxstash-global