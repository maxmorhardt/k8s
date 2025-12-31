helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade prometheus prometheus-community/prometheus --values values.yaml --install --atomic --debug --history-max=3 --namespace monitoring