helm upgrade envoy-gateway oci://docker.io/envoyproxy/gateway-helm \
	--version v1.8.2 \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace envoy-gateway-system \
	--create-namespace \
	--values values.yaml
