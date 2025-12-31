helm upgrade redis oci://docker.io/bitnamicharts/redis \
	--install \
	--atomic \
	--debug \
	--history-max=3 \
	--namespace db \
	--version 23.1.1 \
	--values values.yaml