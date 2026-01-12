helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade redis bitnami/redis \
	--values values.yaml \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace redis