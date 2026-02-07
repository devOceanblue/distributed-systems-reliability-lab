#!/usr/bin/env bash
set -euo pipefail

required_files=(
  services/replay-worker/build.gradle
  services/replay-worker/src/main/java/com/reliabilitylab/replayworker/ReplayWorkerApplication.java
  services/replay-worker/src/main/java/com/reliabilitylab/replayworker/api/ReplayController.java
  services/replay-worker/src/main/java/com/reliabilitylab/replayworker/app/ReplayWorkerService.java
  services/replay-worker/src/main/java/com/reliabilitylab/replayworker/infra/JdbcDlqEventStore.java
  services/replay-worker/src/main/java/com/reliabilitylab/replayworker/infra/KafkaDlqCaptureListener.java
  services/replay-worker/src/main/resources/application.yml
  services/replay-worker/src/main/resources/db/migration/V3__dlq_event.sql
  services/replay-worker/src/test/java/com/reliabilitylab/replayworker/app/ReplayWorkerServiceTest.java
  services/replay-worker/src/test/java/com/reliabilitylab/replayworker/infra/JdbcDlqEventStoreTest.java
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

rg -q "missing dedup_key" services/replay-worker/src/main/java/com/reliabilitylab/replayworker/app/ReplayWorkerService.java || {
  echo "[FAIL] replay-worker must block missing dedup_key"
  exit 1
}

rg -q "REPLAY_RATE_LIMIT_PER_SECOND" services/replay-worker/src/main/resources/application.yml || {
  echo "[FAIL] replay-worker rate limit env toggle missing"
  exit 1
}

echo "[OK] B-0315 replay-worker runtime assets are present"
echo "[INFO] run './gradlew :services:replay-worker:test' for runtime tests"
