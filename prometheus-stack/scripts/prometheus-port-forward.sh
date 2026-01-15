while true; do
	kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
done