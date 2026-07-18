helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm repo update

# renovate: datasource=helm depName=nats registryUrl=https://nats-io.github.io/k8s/helm/charts/
helm upgrade nats nats/nats \
	--version 2.14.2 \
	--values values.yaml \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace nats
