kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/download/v0.19.2/crd.yaml -f https://github.com/rancher/system-upgrade-controller/releases/download/v0.19.2/system-upgrade-controller.yaml
kubectl wait --for=condition=established --timeout=60s crd/plans.upgrade.cattle.io
kubectl apply -f plans.yaml
