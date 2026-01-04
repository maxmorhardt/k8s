helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

kubectl create namespace cnpg-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cnpg-database --dry-run=client -o yaml | kubectl apply -f -

kubectl apply --filename storage.yaml

helm upgrade cloudnativepg cnpg/cloudnative-pg \
	--install \
	--atomic \
	--namespace cnpg-system \
	--create-namespace \
	--values values-operator.yaml 

helm upgrade postgres cnpg/cluster \
	--install \
	--atomic \
	--debug \
	--history-max=3 \
	--namespace cnpg-database \
	--create-namespace \
	--values values-cluster.yaml
