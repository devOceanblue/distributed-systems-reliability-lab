#!/usr/bin/env bash
set -euo pipefail

subject="${1:?subject required}"
schema_file="${2:?schema file required}"
registry_url="${SCHEMA_REGISTRY_URL:-http://localhost:18091}"
sim_mode="${SCHEMA_REGISTRY_SIM:-false}"

[[ -f "$schema_file" ]] || { echo "schema file not found: $schema_file" >&2; exit 1; }

if [[ "$sim_mode" == "true" ]]; then
  state_root="${LAB_STATE_DIR:-.lab/state}/schema-registry"
  mkdir -p "$state_root"

  subject_safe=$(echo "$subject" | sed 's/[^a-zA-Z0-9._-]/_/g')
  versions_file="$state_root/${subject_safe}.versions"
  compat_subject_file="$state_root/${subject_safe}.compat"
  compat_global_file="$state_root/global.compat"
  seq_file="$state_root/id.seq"

  [[ -f "$seq_file" ]] || echo "1" > "$seq_file"
  [[ -f "$versions_file" ]] || : > "$versions_file"

  compatibility="BACKWARD"
  if [[ -f "$compat_subject_file" ]]; then
    compatibility=$(cat "$compat_subject_file")
  elif [[ -f "$compat_global_file" ]]; then
    compatibility=$(cat "$compat_global_file")
  fi

  existing_versions=$(wc -l < "$versions_file" | tr -d ' ')
  schema_name=$(basename "$schema_file")
  if (( existing_versions > 0 )) && [[ "$compatibility" =~ ^(BACKWARD|FULL)$ ]]; then
    if [[ "$schema_name" == *"breaking"* ]]; then
      echo "{\"error_code\":409,\"message\":\"schema incompatible with ${compatibility}\"}" >&2
      exit 1
    fi
  fi

  schema_id=$(cat "$seq_file")
  echo $((schema_id + 1)) > "$seq_file"
  printf '%s\t%s\n' "$schema_id" "$schema_name" >> "$versions_file"
  version=$((existing_versions + 1))

  echo "{\"id\":$schema_id,\"subject\":\"$subject\",\"version\":$version,\"mode\":\"sim\"}"
  echo "[OK] registered $subject id=$schema_id (sim)"
  exit 0
fi

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
