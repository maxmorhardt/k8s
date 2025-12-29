helm repo add codecentric https://codecentric.github.io/helm-charts
helm repo update codecentric

helm upgrade keycloak codecentric/keycloakx \
  --version 7.1.5 \
  --install \
  --atomic \
  --debug \
  --history-max=3 \
  --namespace maxstash-global \
  --timeout 15m0s \
  --values values.yaml