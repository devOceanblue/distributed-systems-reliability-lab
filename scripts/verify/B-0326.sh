#!/usr/bin/env bash
set -euo pipefail

required_files=(
  contracts/avro/schema-order/v1-balance-tags-string.avsc
  contracts/avro/schema-order/v2-balance-tags-array.avsc
  experiments/E-006-schema-deploy-order.md
  scripts/assert/E-006.sh
  services/consumer-service/src/main/java/com/reliabilitylab/consumerservice/infra/ConsumerMessageMapper.java
  services/consumer-service/src/test/java/com/reliabilitylab/consumerservice/infra/ConsumerMessageMapperTest.java
  services/e2e-tests/src/test/java/com/reliabilitylab/e2e/SchemaDeployOrderE2ETest.java
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

rg -q "V1_STRICT|DUAL_READ" services/consumer-service/src/main/java/com/reliabilitylab/consumerservice/config/ConsumerServiceProperties.java || {
  echo "[FAIL] consumer schema read mode toggle missing"
  exit 1
}

rg -q "unsupported tags field for schema_read_mode" services/consumer-service/src/main/java/com/reliabilitylab/consumerservice/infra/ConsumerMessageMapper.java || {
  echo "[FAIL] strict schema parse failure path missing"
  exit 1
}

rg -q "shouldFailInProducerFirstAndConvergeInConsumerFirstDualRead" services/e2e-tests/src/test/java/com/reliabilitylab/e2e/SchemaDeployOrderE2ETest.java || {
  echo "[FAIL] runtime schema deploy-order e2e test missing"
  exit 1
}

echo "[OK] B-0326 schema/deploy-order runtime assets are present"
echo "[INFO] run './gradlew :services:consumer-service:test :services:e2e-tests:test --tests com.reliabilitylab.e2e.SchemaDeployOrderE2ETest'"
