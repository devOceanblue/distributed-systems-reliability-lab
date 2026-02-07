#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e012.stats"

[[ "$abort_range_hidden" == "1" ]] || { echo "abort visibility marker missing"; exit 1; }
[[ "$resume_after_commit" == "1" ]] || { echo "resume marker missing"; exit 1; }

echo "[OK] E-012 assertions passed"
