helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

helm upgrade cloudnativepg cnpg/cloudnative-pg \
	--install \
	--atomic \
	--namespace cnpg-system \
	--create-namespace \
	--values values-operator.yaml \
	--version 0.22.0

helm upgrade postgres cnpg/cluster \
	--install \
	--atomic \
	--debug \
	--history-max=3 \
	--namespace db \
	--values values-cluster.yaml
