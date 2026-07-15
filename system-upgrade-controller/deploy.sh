VERSION=v0.19.2
BASE=https://github.com/rancher/system-upgrade-controller/releases/download/$VERSION

kubectl apply -f $BASE/crd.yaml -f $BASE/system-upgrade-controller.yaml

# plans are rejected until the CRD is served
kubectl wait --for=condition=established --timeout=60s crd/plans.upgrade.cattle.io

kubectl apply -f plans.yaml
