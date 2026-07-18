helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

# renovate: datasource=helm depName=cloudnative-pg registryUrl=https://cloudnative-pg.github.io/charts
helm upgrade cnpg cnpg/cloudnative-pg \
	--install \
	--rollback-on-failure \
	--wait \
	--namespace cnpg-system \
	--create-namespace \
	--version 0.29.0 \
	--values values-operator.yaml 

# renovate: datasource=helm depName=cluster registryUrl=https://cloudnative-pg.github.io/charts
helm upgrade postgres cnpg/cluster \
	--install \
  --rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace cnpg-database \
	--create-namespace \
	--version 0.8.0 \
	--values values-cluster.yaml \
	--timeout 15m
