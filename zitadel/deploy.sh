helm repo add zitadel https://charts.zitadel.com
helm repo update

helm upgrade zitadel zitadel/zitadel \
	--values values.yaml \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace zitadel
