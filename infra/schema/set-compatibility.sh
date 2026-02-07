#!/usr/bin/env bash
set -euo pipefail

compatibility="${1:-BACKWARD}"
subject="${2:-}"
registry_url="${SCHEMA_REGISTRY_URL:-http://localhost:18091}"
sim_mode="${SCHEMA_REGISTRY_SIM:-false}"

if [[ "$sim_mode" == "true" ]]; then
  state_root="${LAB_STATE_DIR:-.lab/state}/schema-registry"
  mkdir -p "$state_root"
  if [[ -n "$subject" ]]; then
    subject_safe=$(echo "$subject" | sed 's/[^a-zA-Z0-9._-]/_/g')
    target="$state_root/${subject_safe}.compat"
  else
    target="$state_root/global.compat"
  fi
  printf '%s\n' "$compatibility" > "$target"
  echo "{\"compatibility\":\"$compatibility\",\"mode\":\"sim\"}"
  echo "[OK] compatibility set to $compatibility${subject:+ for $subject} (sim)"
  exit 0
fi

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
