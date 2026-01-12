helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

helm upgrade cloudnativepg cnpg/cloudnative-pg \
	--install \
	--rollback-on-failure \
	--wait \
	--namespace cnpg-system \
	--create-namespace \
	--version 0.27.0 \
	--values values-operator.yaml 

helm upgrade postgres cnpg/cluster \
	--install \
  --rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace cnpg-database \
	--create-namespace \
	--version 0.4.0 \
	--values values-cluster.yaml \
	--timeout 15m
