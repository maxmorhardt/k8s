helm repo add teleport https://charts.releases.teleport.dev
helm repo update

helm upgrade teleport-cluster teleport/teleport-cluster \
	--install \
  --rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace redis \
	--create-namespace \
  --version 18.6.1 \
	--values values.yaml