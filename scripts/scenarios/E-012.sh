#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e012.stats"
profile="${LAB_PROFILE:-local}"
if [[ "$profile" != "local" ]]; then
  echo "E-012 is local-only; set LAB_PROFILE=local (current=$profile)" >&2
  exit 2
fi

"$SIM" tx-reset
"$SIM" tx-begin tx-e012-abort
"$SIM" tx-send tx-e012-abort e012-a1 A-1 100
"$SIM" tx-send tx-e012-abort e012-a2 A-1 100
"$SIM" tx-send tx-e012-abort e012-a3 A-1 100

leo_open=$("$SIM" tx-leo)
lso_open=$("$SIM" tx-lso)
read_uncommitted_open=$("$SIM" tx-read-uncommitted)
read_committed_open=$("$SIM" tx-read-committed)

"$SIM" tx-abort tx-e012-abort
leo_after_abort=$("$SIM" tx-leo)
lso_after_abort=$("$SIM" tx-lso)
read_uncommitted_after_abort=$("$SIM" tx-read-uncommitted)
read_committed_after_abort=$("$SIM" tx-read-committed)

"$SIM" tx-begin tx-e012-commit
"$SIM" tx-send tx-e012-commit e012-c1 A-1 100
"$SIM" tx-commit tx-e012-commit
leo_after_commit=$("$SIM" tx-leo)
lso_after_commit=$("$SIM" tx-lso)
read_committed_after_commit=$("$SIM" tx-read-committed)
read_uncommitted_after_commit=$("$SIM" tx-read-uncommitted)

abort_range_hidden=$(( read_committed_after_abort == 0 ))
skip_like_visibility=$(( leo_after_abort > read_committed_after_abort ))
resume_after_commit=$(( read_committed_after_commit == 1 ))

cat > "$stats_file" <<STATS
lab_profile=$profile
leo_open=$leo_open
lso_open=$lso_open
read_uncommitted_open=$read_uncommitted_open
read_committed_open=$read_committed_open
leo_after_abort=$leo_after_abort
lso_after_abort=$lso_after_abort
read_uncommitted_after_abort=$read_uncommitted_after_abort
read_committed_after_abort=$read_committed_after_abort
leo_after_commit=$leo_after_commit
lso_after_commit=$lso_after_commit
read_uncommitted_after_commit=$read_uncommitted_after_commit
read_committed_after_commit=$read_committed_after_commit
abort_range_hidden=$abort_range_hidden
skip_like_visibility=$skip_like_visibility
resume_after_commit=$resume_after_commit
STATS
