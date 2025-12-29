set -x

helm package helm

helm upgrade keycloak keycloak-1.0.0.tgz --install --atomic --debug --history-max=3 --namespace maxstash-global --timeout 15m0s

rm keycloak-1.0.0.tgz