#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e014.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"

(( baseline_count > after_ttl_count )) || { echo "retention should reduce rows"; exit 1; }
(( purged_count > 0 )) || { echo "purged rows should be positive"; exit 1; }
(( baseline_bytes > after_ttl_bytes )) || { echo "table size should shrink after retention"; exit 1; }
(( insert_p95_before_ms > insert_p95_after_ms )) || { echo "insert p95 should improve after retention"; exit 1; }
(( partition_drop_removed > 0 )) || { echo "partition drop simulation should remove archive rows"; exit 1; }

echo "[OK] E-014 assertions passed"
