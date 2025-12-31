#!/bin/bash

helm repo add zitadel https://charts.zitadel.com
helm repo update

helm upgrade zitadel zitadel/zitadel \
	--install \
	--atomic \
	--debug \
	--history-max=3 \
	--namespace zitadel \
	--timeout 15m0s \
	--values values.yaml
