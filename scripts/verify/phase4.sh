#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  infra/k6/hotkey.js
  infra/k6/distributed.js
  infra/redis/lua/incr_balance.lua
  contracts/avro/compat/v1.avsc
  contracts/avro/compat/v2_additive.avsc
  contracts/avro/compat/v2_breaking.avsc
  infra/schema/register.sh
  infra/schema/set-compatibility.sh
  scripts/load/processed_event_load.sh
  scripts/data/gen-backfill.sh
  experiments/E-010-redis-cluster-slots.md
  experiments/E-011-hotkey-hotshard.md
  experiments/E-012-tx-abort-skiplike.md
  experiments/E-013-redis-lua-consistency.md
  experiments/E-014-processed-event-retention.md
  experiments/E-015-schema-registry-compat.md
  experiments/E-018-rebalance-storm.md
  experiments/E-019-mysql-deadlock.md
  experiments/E-022-backfill-controlled.md
  experiments/E-023-degradation-partial-outage.md
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

for exp in E-010 E-015 E-018 E-022 E-023; do
  "$EXP" run "$exp" >/dev/null
  "$EXP" assert "$exp" >/dev/null
  "$EXP" cleanup "$exp" >/dev/null
done

echo "[OK] phase4 advanced experiment assets and checks passed"
