DUMP_FILE="postgres-dumpall.sql"
POD_NAME="postgres-cluster-1"
NAMESPACE="cnpg-database"

echo "Copying dump file to pod..."
kubectl cp "$DUMP_FILE" "$NAMESPACE/$POD_NAME:/var/lib/postgresql/data/restore.sql" -c postgres

echo "Copy complete!"

echo -e "\nRun the following in the pod:"
echo "psql -U postgres -f /var/lib/postgresql/data/restore.sql"
echo "rm -f /var/lib/postgresql/data/restore.sql"