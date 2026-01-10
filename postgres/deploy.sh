helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

kubectl apply --filename storage.yaml

helm upgrade cloudnativepg cnpg/cloudnative-pg \
	--install \
	--rollback-on-failure \
	--wait \
	--namespace cnpg-system \
	--create-namespace \
	--values values-operator.yaml 

helm upgrade postgres cnpg/cluster \
	--install \
  --rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace cnpg-database \
	--create-namespace \
	--values values-cluster.yaml
