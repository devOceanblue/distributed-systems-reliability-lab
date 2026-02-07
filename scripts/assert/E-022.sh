#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e022.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"

(( source_rows > 0 )) || { echo "source rows should be positive"; exit 1; }
(( unsafe_db_qps > safe_db_qps )) || { echo "safe mode should reduce db qps"; exit 1; }
(( unsafe_consumer_lag > safe_consumer_lag )) || { echo "safe mode should reduce lag"; exit 1; }
[[ "$resume_supported" == "1" ]] || { echo "resume marker missing"; exit 1; }
[[ "$sampling_validation_passed" == "1" ]] || { echo "sampling validation marker missing"; exit 1; }

echo "[OK] E-022 assertions passed"
