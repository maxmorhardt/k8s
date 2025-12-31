kubectl apply --filename storage.yaml --namespace db

helm upgrade db oci://docker.io/bitnamicharts/postgresql \
	--install \
	--atomic \
	--debug \
	--history-max=3 \
	--namespace db \
	--version 16.7.27 \
	--values values.yaml