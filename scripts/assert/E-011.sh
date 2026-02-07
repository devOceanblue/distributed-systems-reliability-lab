#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e011.stats"

(( failure_p95_ms > success_p95_ms )) || { echo "p95 should improve"; exit 1; }
(( failure_db_qps > success_db_qps )) || { echo "db qps should improve"; exit 1; }

echo "[OK] E-011 assertions passed"
