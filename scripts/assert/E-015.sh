#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e015.stats"

[[ "$additive_registered" == "1" ]] || { echo "additive should register"; exit 1; }
[[ "$breaking_blocked" == "1" ]] || { echo "breaking change should be blocked"; exit 1; }

echo "[OK] E-015 assertions passed"
