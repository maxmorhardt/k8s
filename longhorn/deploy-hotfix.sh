helm repo add longhorn https://charts.longhorn.io
helm repo update

helm upgrade longhorn longhorn/longhorn \
	--values values.yaml \
	--install \
	--rollback-on-failure \
	--wait \
	--debug \
	--history-max=3 \
	--namespace longhorn-system \
	--set image.longhorn.manager.tag=v1.11.0-hotfix-1 \
  --set image.longhorn.instanceManager.tag=v1.11.0-hotfix-2 \
  --set preUpgradeChecker.jobEnabled=false \
  --set upgradeCheck.enabled=false
	
