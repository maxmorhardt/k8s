helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

helm upgrade rancher rancher-latest/rancher --values values.yaml --namespace cattle-system --install --atomic