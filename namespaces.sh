kubectl create namespace cattle-system
kubectl create namespace ingress-nginx

kubectl create namespace cnpg-system
kubectl create namespace cnpg-database
kubectl create namespace redis

kubectl create namespace authentik

kubectl create namespace teleport-cluster
kubectl label namespace teleport-cluster 'pod-security.kubernetes.io/enforce=baseline'

kubectl create namespace squares
kubectl create namespace apps

kubectl create namespace monitoring

kubectl create namespace backups