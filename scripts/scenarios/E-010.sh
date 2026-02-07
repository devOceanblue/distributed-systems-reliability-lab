#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e010.stats"
reset_and_seed 1

cat > "$stats_file" <<'STATS'
failure_crossslot=1
success_hashtag=1
hot_shard_risk=1
STATS
