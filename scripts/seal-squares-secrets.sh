#!/usr/bin/env bash
# Seals every secret the squares split needs, so they can be committed before the cutover:
#   argocd/secrets/valkey/valkey-users.yaml           valkey ACL passwords (default, squares)
#   argocd/secrets/squares/squares-<service>-env.yaml one per service, with only the keys it reads
#
# Database, SMTP, captcha, and CORS settings are copied from the live squares-api-env; the valkey
# passwords and the internal API token are generated. Nothing is printed and no plaintext is written.
#
# usage, from the repository root with kubectl pointed at the cluster:
#   scripts/seal-squares-secrets.sh
set -euo pipefail

cert=sealed-secrets/pub-cert.pem
source_secret=squares-api-env

for bin in kubectl kubeseal openssl; do
  command -v "$bin" >/dev/null || { echo "missing $bin" >&2; exit 1; }
done
[ -f "$cert" ] || { echo "run from the repository root ($cert not found)" >&2; exit 1; }

# a key from the live secret, or empty when it is not set
live() {
  kubectl -n squares get secret "$source_secret" -o "jsonpath={.data.$1}" | base64 -d
}

# reads `key=value` lines on stdin and writes the sealed secret to $3
seal() {
  local name=$1 namespace=$2 out=$3 args=()
  while IFS= read -r line; do
    [ -n "${line#*=}" ] && args+=(--from-literal="$line")
  done
  mkdir -p "$(dirname "$out")"
  kubectl create secret generic "$name" -n "$namespace" "${args[@]}" --dry-run=client -o yaml \
    | kubeseal --format yaml --cert "$cert" >"$out"
  echo "sealed $out (${#args[@]} keys)"
}

valkey_default=$(openssl rand -hex 32)
valkey_squares=$(openssl rand -hex 32)
internal_token=$(openssl rand -hex 32)
redis_url="redis://squares:${valkey_squares}@valkey.valkey.svc:6379/0"

database() {
  for key in DB_HOST DB_PORT DB_USER DB_PASSWORD DB_NAME DB_SSL_MODE \
    DB_READ_HOST DB_READ_PORT DB_READ_USER DB_READ_PASSWORD DB_READ_NAME DB_READ_SSL_MODE; do
    echo "$key=$(live "$key")"
  done
}

printf '%s\n' "default=$valkey_default" "squares=$valkey_squares" \
  | seal valkey-users valkey argocd/secrets/valkey/valkey-users.yaml

{ database; echo "REDIS_URL=$redis_url"; echo "INTERNAL_API_TOKEN=$internal_token"; echo "ALLOWED_ORIGINS=$(live ALLOWED_ORIGINS)"; } \
  | seal squares-contests-env squares argocd/secrets/squares/squares-contests-env.yaml

{ database; echo "REDIS_URL=$redis_url"; echo "ALLOWED_ORIGINS=$(live ALLOWED_ORIGINS)"; } \
  | seal squares-games-env squares argocd/secrets/squares/squares-games-env.yaml

{
  database
  echo "REDIS_URL=$redis_url"
  echo "INTERNAL_API_TOKEN=$internal_token"
  for key in SMTP_HOST SMTP_PORT SMTP_USER SMTP_PASSWORD SUPPORT_EMAIL TURNSTILE_SECRET_KEY CONTACT_RATE_LIMIT ALLOWED_ORIGINS; do
    echo "$key=$(live "$key")"
  done
} | seal squares-accounts-env squares argocd/secrets/squares/squares-accounts-env.yaml

{ echo "REDIS_URL=$redis_url"; echo "INTERNAL_API_TOKEN=$internal_token"; echo "ALLOWED_ORIGINS=$(live ALLOWED_ORIGINS)"; } \
  | seal squares-realtime-env squares argocd/secrets/squares/squares-realtime-env.yaml

echo "done; commit the five files. Re-running generates new passwords, so commit all five together."
