#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  contracts/avro/compat/v1.avsc
  contracts/avro/compat/v2_additive.avsc
  contracts/avro/compat/v2_breaking.avsc
  infra/schema/register.sh
  infra/schema/set-compatibility.sh
  experiments/E-015-schema-registry-compat.md
  scripts/scenarios/E-015.sh
  scripts/assert/E-015.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

SCHEMA_REGISTRY_SIM=true "$EXP" run E-015 >/dev/null
"$EXP" assert E-015 >/dev/null
"$EXP" cleanup E-015 >/dev/null

echo "[OK] B-0338 verification passed"
