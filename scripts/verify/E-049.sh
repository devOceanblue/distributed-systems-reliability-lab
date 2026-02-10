#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DENYLIST="$ROOT_DIR/scripts/compat/elasticache_restricted_commands_denylist.txt"

violations=0
while IFS= read -r cmd; do
  [[ -z "$cmd" ]] && continue
  if rg -n "\\b${cmd}\\b" "$ROOT_DIR/services" "$ROOT_DIR/libs" "$ROOT_DIR/frontend" "$ROOT_DIR/scripts" \
      --glob '!scripts/chaos/*' --glob '!scripts/compat/*' >/dev/null; then
    echo "[FAIL] restricted command usage detected: $cmd"
    violations=$((violations + 1))
  fi
done < "$DENYLIST"

if (( violations > 0 )); then
  exit 1
fi

echo "[OK] E-049 compatibility gate passed"
