#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e-iam-002.stats"
[[ "$write_denied" == "1" ]] || { echo "write denied marker missing"; exit 1; }
[[ "$access_denied_error" == "1" ]] || { echo "access denied marker missing"; exit 1; }
echo "[OK] E-IAM-002 assertions passed"
