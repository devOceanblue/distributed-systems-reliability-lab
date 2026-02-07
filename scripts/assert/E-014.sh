#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e014.stats"

(( baseline_count > after_ttl_count )) || { echo "retention should reduce rows"; exit 1; }
[[ "$partition_drop_simulated" == "1" ]] || { echo "partition simulation marker missing"; exit 1; }

echo "[OK] E-014 assertions passed"
