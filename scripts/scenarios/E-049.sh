#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"
OUT_DIR="$STATE_DIR/e049"
mkdir -p "$OUT_DIR"

if "$ROOT_DIR/scripts/verify/E-049.sh" > "$OUT_DIR/gate.log" 2>&1; then
  violations=0
else
  violations=1
fi

cat > "$STATE_DIR/e049.stats" <<STATS
violations=$violations
gate=restricted_commands
denylist_file=scripts/compat/elasticache_restricted_commands_denylist.txt
STATS

cat > "$OUT_DIR/report.md" <<REPORT
# E-049 report

- violations=$violations
- gate=restricted_commands
- denylist_file=scripts/compat/elasticache_restricted_commands_denylist.txt
REPORT

echo "[OK] E-049 scenario completed"
