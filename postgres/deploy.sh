kubectl apply --filename storage.yaml --namespace db

helm upgrade db oci://docker.io/bitnamicharts/postgresql \
	--install \
	--atomic \
	--debug \
	--history-max=3 \
	--namespace db \
	--values values.yaml \
	--version 18.2.0