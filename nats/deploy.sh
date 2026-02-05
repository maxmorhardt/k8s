helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm repo update

helm upgrade nats nats/nats \
	--values values.yaml \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace nats
