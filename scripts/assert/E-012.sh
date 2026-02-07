#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e012.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"

[[ "$lab_profile" == "local" ]] || { echo "E-012 must run with LAB_PROFILE=local"; exit 1; }
[[ "$abort_range_hidden" == "1" ]] || { echo "abort visibility marker missing"; exit 1; }
[[ "$skip_like_visibility" == "1" ]] || { echo "skip-like visibility marker missing"; exit 1; }
[[ "$resume_after_commit" == "1" ]] || { echo "resume marker missing"; exit 1; }
(( lso_open < leo_open )) || { echo "open tx should keep LSO behind LEO"; exit 1; }
(( read_committed_after_abort == 0 )) || { echo "aborted range must not be visible to read_committed"; exit 1; }
(( lso_after_abort == leo_after_abort )) || { echo "after abort, LSO should catch up"; exit 1; }
(( read_committed_after_commit == 1 )) || { echo "committed record should be delivered after resume"; exit 1; }

echo "[OK] E-012 assertions passed"
