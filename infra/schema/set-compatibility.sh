#!/usr/bin/env bash
set -euo pipefail

compatibility="${1:-BACKWARD}"
subject="${2:-}"
registry_url="${SCHEMA_REGISTRY_URL:-http://localhost:18091}"

if [[ -n "$subject" ]]; then
  endpoint="$registry_url/config/$subject"
else
  endpoint="$registry_url/config"
fi

payload="{\"compatibility\":\"$compatibility\"}"
response=$(curl -fsS -X PUT \
  -H 'Content-Type: application/vnd.schemaregistry.v1+json' \
  --data "$payload" \
  "$endpoint")

echo "$response"
echo "[OK] compatibility set to $compatibility${subject:+ for $subject}"
