kubectl apply --filename storage.yaml --namespace maxstash-global

helm upgrade db oci://.docker.io/bitnamicharts/postgresql \
	--install \
	--atomic \
	--debug \
	--history-max=3 \
	--namespace maxstash-global \
	--version 16.7.27 \
	--values values.yaml