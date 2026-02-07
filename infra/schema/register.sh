#!/usr/bin/env bash
set -euo pipefail

subject="${1:?subject required}"
schema_file="${2:?schema file required}"
registry_url="${SCHEMA_REGISTRY_URL:-http://localhost:18091}"

[[ -f "$schema_file" ]] || { echo "schema file not found: $schema_file" >&2; exit 1; }

escaped_schema=$(sed ':a;N;$!ba;s/\\/\\\\/g;s/"/\\"/g;s/\n/\\n/g' "$schema_file")
payload="{\"schema\":\"$escaped_schema\"}"

response=$(curl -fsS -X POST \
  -H 'Content-Type: application/vnd.schemaregistry.v1+json' \
  --data "$payload" \
  "$registry_url/subjects/$subject/versions")

schema_id=$(echo "$response" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')
if [[ -z "$schema_id" ]]; then
  echo "failed to parse schema id from response: $response" >&2
  exit 1
fi

echo "$response"
echo "[OK] registered $subject id=$schema_id"
