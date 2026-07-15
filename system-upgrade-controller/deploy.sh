kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/latest/download/crd.yaml -f https://github.com/rancher/system-upgrade-controller/releases/latest/download/system-upgrade-controller.yaml
kubectl wait --for=condition=established --timeout=60s crd/plans.upgrade.cattle.io
kubectl apply -f plans.yaml
