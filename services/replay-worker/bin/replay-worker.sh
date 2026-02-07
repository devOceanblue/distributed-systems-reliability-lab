#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"

account_filter="${REPLAY_ACCOUNT_ID:-*}"
dry_run="${DRY_RUN:-false}"

"$SIM" replay-dlq "$account_filter" "$dry_run"
