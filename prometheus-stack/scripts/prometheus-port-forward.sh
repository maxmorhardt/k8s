while true; do
	kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 80:9090
done