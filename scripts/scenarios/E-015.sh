#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e015.stats"
reset_and_seed 1
mkdir -p "$STATE_DIR/schema-registry"
: > "$STATE_DIR/schema-registry/id.seq"
rm -f "$STATE_DIR"/schema-registry/*.versions "$STATE_DIR"/schema-registry/*.compat 2>/dev/null || true

subject_backward="account.balance.value"
subject_full="account.balance.full.value"
subject_versioned="account.balance.v2.value"

env SCHEMA_REGISTRY_SIM=true "$ROOT_DIR/infra/schema/set-compatibility.sh" BACKWARD >/dev/null
env SCHEMA_REGISTRY_SIM=true "$ROOT_DIR/infra/schema/register.sh" "$subject_backward" "$ROOT_DIR/contracts/avro/compat/v1.avsc" >/dev/null
env SCHEMA_REGISTRY_SIM=true "$ROOT_DIR/infra/schema/register.sh" "$subject_backward" "$ROOT_DIR/contracts/avro/compat/v2_additive.avsc" >/dev/null

set +e
env SCHEMA_REGISTRY_SIM=true "$ROOT_DIR/infra/schema/register.sh" "$subject_backward" "$ROOT_DIR/contracts/avro/compat/v2_breaking.avsc" >/dev/null 2>&1
backward_breaking_rc=$?
set -e

env SCHEMA_REGISTRY_SIM=true "$ROOT_DIR/infra/schema/set-compatibility.sh" FULL "$subject_full" >/dev/null
env SCHEMA_REGISTRY_SIM=true "$ROOT_DIR/infra/schema/register.sh" "$subject_full" "$ROOT_DIR/contracts/avro/compat/v1.avsc" >/dev/null
env SCHEMA_REGISTRY_SIM=true "$ROOT_DIR/infra/schema/register.sh" "$subject_full" "$ROOT_DIR/contracts/avro/compat/v2_additive.avsc" >/dev/null

set +e
env SCHEMA_REGISTRY_SIM=true "$ROOT_DIR/infra/schema/register.sh" "$subject_full" "$ROOT_DIR/contracts/avro/compat/v2_breaking.avsc" >/dev/null 2>&1
full_breaking_rc=$?
set -e

# Versioned subject/topic split path.
env SCHEMA_REGISTRY_SIM=true "$ROOT_DIR/infra/schema/register.sh" "$subject_versioned" "$ROOT_DIR/contracts/avro/compat/v2_breaking.avsc" >/dev/null

cat > "$stats_file" <<STATS
backward_additive_registered=1
backward_breaking_blocked=$(( backward_breaking_rc != 0 ))
full_additive_registered=1
full_breaking_blocked=$(( full_breaking_rc != 0 ))
versioned_subject_registered=1
STATS
