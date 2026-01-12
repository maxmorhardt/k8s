while true; do
    kubectl port-forward -n cnpg-database pod/postgres-cluster-1 5433:5432
done