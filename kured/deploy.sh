helm repo add kubereboot https://kubereboot.github.io/charts
helm repo update

helm upgrade kured kubereboot/kured \
  --values values.yaml \
  --install \
  --namespace kube-system \
  --rollback-on-failure \
  --wait \
  --history-max=3
