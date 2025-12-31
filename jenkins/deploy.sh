kubectl apply --filename storage.yaml --namespace jenkins
kubectl apply --filename sa.yaml --namespace jenkins

helm repo add jenkinsci https://charts.jenkins.io
helm repo update

helm upgrade jenkins jenkinsci/jenkins --values values.yaml --install --atomic --debug --history-max=3 --namespace jenkins --timeout 15m0s