helm repo add dandydev https://dandydeveloper.github.io/charts
helm repo update

helm upgrade --install redis dandydev/redis-ha \
  --namespace redis \
  --create-namespace \
  -f values.yaml