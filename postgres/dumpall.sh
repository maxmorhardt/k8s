DUMP_FILE="postgres-dumpall.sql"
POD_NAME="postgres-cluster-1"
NAMESPACE="cnpg-database"

echo "Dumping all databases from PostgreSQL cluster..."
kubectl exec -n "$NAMESPACE" "$POD_NAME" -c postgres -- pg_dumpall -U postgres > "$DUMP_FILE"

echo "Dump complete! Saved to $DUMP_FILE"
