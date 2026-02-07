#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e-iam-001.stats"
[[ "$consumer_group_permission_missing" == "1" ]] || { echo "missing permission marker"; exit 1; }
[[ "$join_failed" == "1" ]] || { echo "join failure marker missing"; exit 1; }
echo "[OK] E-IAM-001 assertions passed"
