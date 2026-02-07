#!/usr/bin/env bash
set -euo pipefail

required_files=(
  experiments/E-005-dlq-replay.md
  scripts/scenarios/E-005.sh
  scripts/assert/E-005.sh
  services/e2e-tests/src/test/java/com/reliabilitylab/e2e/RetryDlqReplayE2ETest.java
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

rg -q "FORCE_PERMANENT_ERROR_ON_ACCOUNT_ID=A-3" scripts/scenarios/E-005.sh || {
  echo "[FAIL] E-005 scenario must route A-3 to DLQ deterministically"
  exit 1
}

rg -q "count processed" scripts/assert/E-005.sh || {
  echo "[FAIL] E-005 assert must verify dedup-safe processed count"
  exit 1
}

rg -q "shouldRecoverFromDlqReplayAndStayIdempotentOnReplayDuplicates" services/e2e-tests/src/test/java/com/reliabilitylab/e2e/RetryDlqReplayE2ETest.java || {
  echo "[FAIL] runtime E2E test for retry->DLQ->replay is missing"
  exit 1
}

echo "[OK] B-0325 E-005 runtime/simulation assets are present"
echo "[INFO] run './gradlew :services:e2e-tests:test --tests com.reliabilitylab.e2e.RetryDlqReplayE2ETest'"
