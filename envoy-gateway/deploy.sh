helm upgrade eg oci://docker.io/envoyproxy/gateway-helm \
	--install \
	--version v1.5.6 \
  --rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace envoy-gateway-system

kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
kubectl apply -f gateway.yaml -n envoy-gateway-system