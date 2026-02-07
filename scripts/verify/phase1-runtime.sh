#!/usr/bin/env bash
set -euo pipefail

required_files=(
  settings.gradle
  build.gradle
  libs/event-core/build.gradle
  services/command-service/build.gradle
  services/outbox-relay/build.gradle
  services/consumer-service/build.gradle
  services/query-service/build.gradle
  services/e2e-tests/build.gradle
  services/command-service/src/main/java/com/reliabilitylab/commandservice/CommandServiceApplication.java
  services/command-service/src/main/java/com/reliabilitylab/commandservice/api/CommandController.java
  services/command-service/src/main/java/com/reliabilitylab/commandservice/app/CommandApplicationService.java
  services/command-service/src/main/java/com/reliabilitylab/commandservice/app/CommandTxHandler.java
  services/command-service/src/main/java/com/reliabilitylab/commandservice/infra/CommandJdbcRepository.java
  services/outbox-relay/src/main/java/com/reliabilitylab/outboxrelay/OutboxRelayApplication.java
  services/outbox-relay/src/main/java/com/reliabilitylab/outboxrelay/app/OutboxRelayService.java
  services/outbox-relay/src/main/java/com/reliabilitylab/outboxrelay/infra/OutboxEventRepository.java
  services/consumer-service/src/main/java/com/reliabilitylab/consumerservice/ConsumerServiceApplication.java
  services/consumer-service/src/main/java/com/reliabilitylab/consumerservice/app/ConsumerProcessingService.java
  services/consumer-service/src/main/java/com/reliabilitylab/consumerservice/infra/ConsumerJdbcRepository.java
  services/query-service/src/main/java/com/reliabilitylab/queryservice/QueryServiceApplication.java
  services/query-service/src/main/java/com/reliabilitylab/queryservice/api/QueryController.java
  services/query-service/src/main/java/com/reliabilitylab/queryservice/app/QueryBalanceService.java
  services/query-service/src/main/java/com/reliabilitylab/queryservice/infra/RedisBalanceCacheStore.java
  services/command-service/src/main/resources/application.yml
  services/outbox-relay/src/main/resources/application.yml
  services/consumer-service/src/main/resources/application.yml
  services/query-service/src/main/resources/application.yml
  services/command-service/src/main/resources/db/migration/V1__core.sql
  services/outbox-relay/src/main/resources/db/migration/V1__core.sql
  services/consumer-service/src/main/resources/db/migration/V1__core.sql
  services/query-service/src/main/resources/db/migration/V1__core.sql
  services/command-service/src/test/java/com/reliabilitylab/commandservice/app/CommandApplicationServiceTest.java
  services/outbox-relay/src/test/java/com/reliabilitylab/outboxrelay/app/OutboxRelayServiceTest.java
  services/consumer-service/src/test/java/com/reliabilitylab/consumerservice/app/ConsumerProcessingServiceTest.java
  services/consumer-service/src/test/java/com/reliabilitylab/consumerservice/app/ConsumerTxHandlerTest.java
  services/query-service/src/test/java/com/reliabilitylab/queryservice/app/QueryBalanceServiceTest.java
  services/e2e-tests/src/test/java/com/reliabilitylab/e2e/CommandRelayConsumerE2ETest.java
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

rg -q "FAILPOINT_AFTER_KAFKA_SEND_BEFORE_MARK_SENT|FAILPOINT_BEFORE_KAFKA_SEND" services/outbox-relay/src/main/java/com/reliabilitylab/outboxrelay/app/OutboxRelayService.java || {
  echo "[FAIL] relay failpoints missing"
  exit 1
}

rg -q "FAILPOINT_AFTER_OFFSET_COMMIT_BEFORE_DB_COMMIT" services/consumer-service/src/main/java/com/reliabilitylab/consumerservice/app/ConsumerProcessingService.java || {
  echo "[FAIL] consumer offset failpoint missing"
  exit 1
}

rg -q "STAMPEDE_PROTECTION" services/query-service/src/main/resources/application.yml || {
  echo "[FAIL] query-service stampede toggle missing"
  exit 1
}

rg -q "CACHE_INVALIDATION_MODE" services/consumer-service/src/main/resources/application.yml || {
  echo "[FAIL] consumer cache invalidation toggle missing"
  exit 1
}

rg -q "CommandRelayConsumerE2ETest" services/e2e-tests/src/test/java/com/reliabilitylab/e2e/CommandRelayConsumerE2ETest.java || {
  echo "[FAIL] e2e test missing"
  exit 1
}

echo "[OK] phase1 runtime scaffold assets are present"
