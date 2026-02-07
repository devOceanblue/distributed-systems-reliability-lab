#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e-iam-003.stats"
[[ "$idempotent_permission_missing" == "1" ]] || { echo "idempotent permission marker missing"; exit 1; }
[[ "$producer_send_failed" == "1" ]] || { echo "producer send failure marker missing"; exit 1; }
echo "[OK] E-IAM-003 assertions passed"
