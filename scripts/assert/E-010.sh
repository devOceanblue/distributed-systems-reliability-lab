#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e010.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"

[[ "$failure_crossslot" == "1" ]] || { echo "crossslot failure missing"; exit 1; }
[[ "$success_hashtag" == "1" ]] || { echo "hashtag success missing"; exit 1; }
[[ "$hot_shard_risk" == "1" ]] || { echo "hot shard risk should be detected"; exit 1; }
(( hot_shard_ratio_pct >= 90 )) || { echo "hot shard concentration should be high"; exit 1; }

echo "[OK] E-010 assertions passed"
