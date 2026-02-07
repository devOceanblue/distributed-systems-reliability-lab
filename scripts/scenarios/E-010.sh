#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e010.stats"
reset_and_seed 1

slot_for_key() {
  local key="$1"
  local hash_input="$key"
  local tag
  if [[ "$key" =~ \{([^}]*)\} ]]; then
    tag="${BASH_REMATCH[1]}"
    if [[ -n "$tag" ]]; then
      hash_input="$tag"
    fi
  fi
  echo $(( $(cksum <<<"$hash_input" | awk '{print $1}') % 16384 ))
}

slot_a=$(slot_for_key "user:1:profile")
slot_b=$(slot_for_key "user:1:orders")
failure_crossslot=$(( slot_a != slot_b ))

slot_c=$(slot_for_key "user:{1}:profile")
slot_d=$(slot_for_key "user:{1}:orders")
success_hashtag=$(( slot_c == slot_d ))

hot_same_slot=0
hot_total=100
for idx in $(seq 1 "$hot_total"); do
  slot=$(slot_for_key "balance:{hot}:$idx")
  [[ "$slot" == "$(slot_for_key "balance:{hot}:1")" ]] && hot_same_slot=$((hot_same_slot + 1))
done
hot_shard_ratio_pct=$((hot_same_slot * 100 / hot_total))
hot_shard_risk=$(( hot_shard_ratio_pct >= 90 ))

cat > "$stats_file" <<STATS
failure_slot_a=$slot_a
failure_slot_b=$slot_b
failure_crossslot=$failure_crossslot
success_slot_a=$slot_c
success_slot_b=$slot_d
success_hashtag=$success_hashtag
hot_shard_ratio_pct=$hot_shard_ratio_pct
hot_shard_risk=$hot_shard_risk
STATS
