#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

required_files=(
  libs/kafka-client/build.gradle
  libs/kafka-client/src/main/java/com/reliabilitylab/kafkaclient/MskIamKafkaProperties.java
  libs/kafka-client/src/test/java/com/reliabilitylab/kafkaclient/MskIamKafkaPropertiesTest.java
  docs/MSK_IAM_CLIENT.md
  scripts/smoke/aws-kafka-produce.sh
  scripts/smoke/aws-kafka-consume.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

grep -q "aws-msk-iam-auth" "$ROOT_DIR/libs/kafka-client/build.gradle" || { echo "[FAIL] aws-msk-iam-auth dependency missing"; exit 1; }
grep -q "AWS_MSK_IAM" "$ROOT_DIR/libs/kafka-client/src/main/java/com/reliabilitylab/kafkaclient/MskIamKafkaProperties.java" || { echo "[FAIL] AWS_MSK_IAM settings missing"; exit 1; }
grep -q "buildFromEnv" "$ROOT_DIR/libs/kafka-client/src/main/java/com/reliabilitylab/kafkaclient/MskIamKafkaProperties.java" || { echo "[FAIL] env-based property builder missing"; exit 1; }
grep -q "auth_error" "$ROOT_DIR/scripts/smoke/aws-kafka-produce.sh" || { echo "[FAIL] auth classification missing in produce smoke"; exit 1; }
grep -q "network_error" "$ROOT_DIR/scripts/smoke/aws-kafka-produce.sh" || { echo "[FAIL] network classification missing in produce smoke"; exit 1; }
grep -q "authz_error" "$ROOT_DIR/scripts/smoke/aws-kafka-produce.sh" || { echo "[FAIL] authz classification missing in produce smoke"; exit 1; }

echo "[OK] B-0351 verification passed"
