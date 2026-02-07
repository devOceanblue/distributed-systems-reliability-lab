#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e010.stats"

[[ "$failure_crossslot" == "1" ]] || { echo "crossslot failure missing"; exit 1; }
[[ "$success_hashtag" == "1" ]] || { echo "hashtag success missing"; exit 1; }

echo "[OK] E-010 assertions passed"
