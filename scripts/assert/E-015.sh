#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e015.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"

[[ "$backward_additive_registered" == "1" ]] || { echo "BACKWARD additive should register"; exit 1; }
[[ "$backward_breaking_blocked" == "1" ]] || { echo "BACKWARD breaking should be blocked"; exit 1; }
[[ "$full_additive_registered" == "1" ]] || { echo "FULL additive should register"; exit 1; }
[[ "$full_breaking_blocked" == "1" ]] || { echo "FULL breaking should be blocked"; exit 1; }
[[ "$versioned_subject_registered" == "1" ]] || { echo "versioned subject should register"; exit 1; }

echo "[OK] E-015 assertions passed"
