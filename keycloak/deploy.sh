helm upgrade keycloak oci://registry-1.docker.io/bitnamicharts/keycloak \
  --version 23.2.1 \
  --install \
  --atomic \
  --debug \
  --history-max=3 \
  --namespace maxstash-global \
  --timeout 15m0s \
  --values values.yaml