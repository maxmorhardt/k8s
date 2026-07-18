helm repo add kubereboot https://kubereboot.github.io/charts
helm repo update

# renovate: datasource=helm depName=kured registryUrl=https://kubereboot.github.io/charts
helm upgrade kured kubereboot/kured \
  --version 6.1.0 \
  --values values.yaml \
  --install \
  --namespace kube-system \
  --rollback-on-failure \
  --wait \
  --history-max=3
