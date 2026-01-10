helm upgrade redis oci://docker.io/bitnamicharts/redis \
	--install \
  --rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace redis \
	--create-namespace \
	--version 24.1.0 \
	--values values.yaml