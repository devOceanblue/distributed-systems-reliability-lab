#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e015.stats"
reset_and_seed 1

subject="account.balance.value"
"$ROOT_DIR/infra/schema/set-compatibility.sh" BACKWARD >/dev/null
"$ROOT_DIR/infra/schema/register.sh" "$subject" "$ROOT_DIR/contracts/avro/compat/v1.avsc" >/dev/null
"$ROOT_DIR/infra/schema/register.sh" "$subject" "$ROOT_DIR/contracts/avro/compat/v2_additive.avsc" >/dev/null

set +e
"$ROOT_DIR/infra/schema/register.sh" "$subject" "$ROOT_DIR/contracts/avro/compat/v2_breaking.avsc" >/dev/null 2>&1
breaking_rc=$?
set -e

cat > "$stats_file" <<STATS
additive_registered=1
breaking_blocked=$(( breaking_rc != 0 ))
STATS
