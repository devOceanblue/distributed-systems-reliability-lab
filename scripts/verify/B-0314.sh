#!/usr/bin/env bash
set -euo pipefail

required_files=(
  services/query-service/build.gradle
  services/query-service/src/main/java/com/reliabilitylab/queryservice/QueryServiceApplication.java
  services/query-service/src/main/java/com/reliabilitylab/queryservice/app/QueryBalanceService.java
  services/query-service/src/main/java/com/reliabilitylab/queryservice/config/QueryServiceProperties.java
  services/query-service/src/main/java/com/reliabilitylab/queryservice/infra/RedisBalanceCacheStore.java
  services/query-service/src/main/resources/application.yml
  services/query-service/src/test/java/com/reliabilitylab/queryservice/app/QueryBalanceServiceTest.java
  services/consumer-service/src/main/java/com/reliabilitylab/consumerservice/app/ProjectionCacheInvalidator.java
  services/consumer-service/src/main/java/com/reliabilitylab/consumerservice/infra/RedisProjectionCacheInvalidator.java
  services/consumer-service/src/test/java/com/reliabilitylab/consumerservice/app/ConsumerTxHandlerTest.java
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

rg -q "STAMPEDE_PROTECTION" services/query-service/src/main/resources/application.yml || {
  echo "[FAIL] query-service must expose STAMPEDE_PROTECTION env toggle"
  exit 1
}

rg -q "VERSIONED" services/consumer-service/src/main/java/com/reliabilitylab/consumerservice/config/ConsumerServiceProperties.java || {
  echo "[FAIL] consumer cache invalidation mode must include VERSIONED"
  exit 1
}

echo "[OK] B-0314 query/cache invalidation runtime assets are present"
echo "[INFO] run './gradlew :services:query-service:test :services:consumer-service:test' for runtime tests"
