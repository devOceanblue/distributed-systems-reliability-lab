#!/usr/bin/env bash
set -euo pipefail

required_files=(
  settings.gradle
  build.gradle
  libs/event-core/build.gradle
  services/command-service/build.gradle
  services/command-service/src/main/java/com/reliabilitylab/commandservice/CommandServiceApplication.java
  services/command-service/src/main/java/com/reliabilitylab/commandservice/api/CommandController.java
  services/command-service/src/main/java/com/reliabilitylab/commandservice/app/CommandApplicationService.java
  services/command-service/src/main/java/com/reliabilitylab/commandservice/app/CommandTxHandler.java
  services/command-service/src/main/java/com/reliabilitylab/commandservice/infra/CommandJdbcRepository.java
  services/command-service/src/main/resources/application.yml
  services/command-service/src/main/resources/db/migration/V1__core.sql
  services/command-service/src/test/java/com/reliabilitylab/commandservice/app/CommandApplicationServiceTest.java
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

rg -q "POST /accounts/\{id\}/deposit|@PostMapping\(\"/\{id\}/deposit\"\)" services/command-service/src/main/java/com/reliabilitylab/commandservice/api/CommandController.java || {
  echo "[FAIL] deposit endpoint missing"
  exit 1
}

rg -q "FAILPOINT_AFTER_DB_COMMIT_BEFORE_KAFKA_SEND" services/command-service/src/main/java/com/reliabilitylab/commandservice/app/CommandApplicationService.java || {
  echo "[FAIL] direct mode failpoint missing"
  exit 1
}

rg -q "INSERT INTO outbox_event" services/command-service/src/main/java/com/reliabilitylab/commandservice/infra/CommandJdbcRepository.java || {
  echo "[FAIL] outbox insert query missing"
  exit 1
}

echo "[OK] phase1 runtime scaffold assets are present"
