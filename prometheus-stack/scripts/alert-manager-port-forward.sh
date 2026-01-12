while true; do
	kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 80:9093
done