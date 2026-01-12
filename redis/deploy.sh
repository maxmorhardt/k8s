helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade --install redis bitnami/redis \
  --namespace redis \
  --create-namespace \
  -f values.yaml