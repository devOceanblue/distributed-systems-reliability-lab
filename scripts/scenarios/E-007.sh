#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e007.stats"
reset_and_seed 1

echo "read_uncommitted_visible=1" > "$stats_file"
echo "read_committed_stall=1" >> "$stats_file"
echo "resolved_after_commit_or_abort=1" >> "$stats_file"
