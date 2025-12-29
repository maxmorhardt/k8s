kubectl apply --filename storage.yaml --namespace maxstash-global
kubectl apply --filename sa.yaml --namespace maxstash-global

helm repo add jenkinsci https://charts.jenkins.io
helm repo update

helm upgrade jenkins jenkinsci/jenkins --values values.yaml --install --atomic --debug --history-max=3 --namespace maxstash-global --timeout 15m0s