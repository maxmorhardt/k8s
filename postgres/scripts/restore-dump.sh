DUMP_FILE=""
POD_NAME="postgres-cluster-1"
NAMESPACE="cnpg-database"

echo "Restoring database"
cat "$DUMP_FILE" | kubectl exec -i -n "$NAMESPACE" "$POD_NAME" -c postgres -- psql -U postgres

echo "Restore complete!"
