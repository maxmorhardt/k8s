helm upgrade redis oci://docker.io/bitnamicharts/redis \
	--install \
	--atomic \
	--debug \
	--history-max=3 \
	--namespace db \
	--version 24.1.0 \
	--values values.yaml