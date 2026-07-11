helm repo add dex https://charts.dexidp.io
helm repo update

helm upgrade dex dex/dex \
	--version 0.24.1 \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace dex \
	--create-namespace \
	--values values.yaml
