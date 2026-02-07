#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e012.stats"
reset_and_seed 1

cat > "$stats_file" <<'STATS'
abort_range_hidden=1
skip_like_visibility=1
resume_after_commit=1
STATS
