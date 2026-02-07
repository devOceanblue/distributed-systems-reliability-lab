#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e007.stats"
profile="${LAB_PROFILE:-local}"
if [[ "$profile" != "local" ]]; then
  echo "E-007 is local-only; set LAB_PROFILE=local (current=$profile)" >&2
  exit 2
fi

"$SIM" tx-reset
"$SIM" tx-begin tx-e007-1
"$SIM" tx-send tx-e007-1 e007-1 A-1 100

leo_open=$("$SIM" tx-leo)
hw_open=$("$SIM" tx-hw)
lso_open=$("$SIM" tx-lso)
read_uncommitted_open=$("$SIM" tx-read-uncommitted)
read_committed_open=$("$SIM" tx-read-committed)

"$SIM" tx-commit tx-e007-1
lso_after_resolve=$("$SIM" tx-lso)
read_committed_after_resolve=$("$SIM" tx-read-committed)

cat > "$stats_file" <<STATS
lab_profile=$profile
leo_open=$leo_open
hw_open=$hw_open
lso_open=$lso_open
read_uncommitted_open=$read_uncommitted_open
read_committed_open=$read_committed_open
lso_after_resolve=$lso_after_resolve
read_committed_after_resolve=$read_committed_after_resolve
STATS
