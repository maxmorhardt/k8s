helm repo add longhorn https://charts.longhorn.io
helm repo update

helm upgrade longhorn longhorn/longhorn \
	--values values.yaml \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace longhorn-system \
	--create-namespace
