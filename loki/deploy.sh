kubectl apply --filename storage.yaml --namespace monitoring

helm repo add grafana https://grafana.github.io/helm-charts 
helm repo update

helm upgrade loki grafana/loki --values values.yaml --install --atomic --debug --history-max=3 --namespace monitoring