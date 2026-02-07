#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="$ROOT_DIR/.lab/state/e007.stats"

[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
source "$STATS_FILE"

[[ "$lab_profile" == "local" ]] || { echo "E-007 must run with LAB_PROFILE=local"; exit 1; }
[[ "$read_uncommitted_open" == "1" ]] || { echo "read_uncommitted should see open transactional record"; exit 1; }
[[ "$read_committed_open" == "0" ]] || { echo "read_committed should stall while txn is open"; exit 1; }
(( lso_open < leo_open )) || { echo "LSO should lag behind LEO when open transaction exists"; exit 1; }
(( hw_open == leo_open )) || { echo "single replica simulation expects HW == LEO"; exit 1; }
[[ "$read_committed_after_resolve" == "1" ]] || { echo "read_committed should progress after txn resolve"; exit 1; }
(( lso_after_resolve == leo_open )) || { echo "LSO should catch up to LEO after resolve"; exit 1; }

echo "[OK] E-007 assertions passed"
