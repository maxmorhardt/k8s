for vol in $(kubectl get volumes.longhorn.io -n longhorn-system -o json | jq -r '.items[] | select(.status.state == "detached") | .metadata.name' | tr -d '\r'); do
  pv_exists=$(kubectl get pv -o json | jq -r --arg vol "$vol" '.items[] | select(.spec.csi.volumeHandle == $vol) | .metadata.name')
  pvc_exists=$(kubectl get pvc --all-namespaces -o json | jq -r --arg vol "$vol" '.items[] | select(.spec.volumeName == $vol) | .metadata.name')
  if [[ -z "$pv_exists" && -z "$pvc_exists" ]]; then
    echo "Deleting Longhorn volume: $vol"
    kubectl delete volume.longhorn.io "$vol" -n longhorn-system
  else
    echo "Skipping $vol: PV or PVC still exists"
  fi
done