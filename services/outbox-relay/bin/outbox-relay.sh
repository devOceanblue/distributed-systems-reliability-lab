#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"

fail_after_send_before_mark_sent="${FAILPOINT_AFTER_KAFKA_SEND_BEFORE_MARK_SENT:-false}"
fail_before_send="${FAILPOINT_BEFORE_KAFKA_SEND:-false}"

"$SIM" relay-once "$fail_after_send_before_mark_sent" "$fail_before_send"
