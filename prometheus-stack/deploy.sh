helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
	--values values.yaml \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace monitoring \
	--create-namespace