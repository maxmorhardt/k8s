## Notes
- Apply storage.yaml before running ./deploy.sh
- chown -R 1000:1000 /data on max-worker
- Ingress is not enabled -- visualize with grafana and use kube dns (i.e. my-svc.my-namespace.svc.cluster-domain.example)