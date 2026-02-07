#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e-iam-002.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"
[[ -n "$target_topic" ]] || { echo "target topic should be set"; exit 1; }
[[ "$write_denied" == "1" ]] || { echo "write denied marker missing"; exit 1; }
[[ "$access_denied_error" == "1" ]] || { echo "access denied marker missing"; exit 1; }
echo "[OK] E-IAM-002 assertions passed"
