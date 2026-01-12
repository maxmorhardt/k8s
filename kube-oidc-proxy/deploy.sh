helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade kube-oidc-proxy jetstack/kube-oidc-proxy \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace kube-system \
	--values values.yaml
