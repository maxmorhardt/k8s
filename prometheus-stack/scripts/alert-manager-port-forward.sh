while true; do
	kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
done