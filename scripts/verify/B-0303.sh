#!/usr/bin/env bash
set -euo pipefail

required_files=(
  contracts/avro/event-envelope.avsc
  contracts/avro/account-balance-changed-v1.avsc
  libs/event-core/src/main/resources/avro/event-envelope.avsc
  libs/event-core/src/main/resources/avro/account-balance-changed-v1.avsc
  libs/event-core/src/main/java/com/reliabilitylab/eventcore/avro/EventEnvelopeAvroCodec.java
  libs/event-core/src/main/java/com/reliabilitylab/eventcore/schema/SchemaRegistryRestClient.java
  infra/schema/register.sh
  infra/schema/set-compatibility.sh
  infra/schema/register-core-schemas.sh
  docs/SCHEMA_REGISTRY.md
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

bash -n infra/schema/register.sh
bash -n infra/schema/set-compatibility.sh
bash -n infra/schema/register-core-schemas.sh

rg -q "dedup_key" contracts/avro/event-envelope.avsc || {
  echo "[FAIL] event-envelope schema must include dedup_key"
  exit 1
}

rg -q "require\\(envelope\\.dedupKey\\(\\), \"dedup_key\"\\)" libs/event-core/src/main/java/com/reliabilitylab/eventcore/EventValidator.java || {
  echo "[FAIL] EventValidator must enforce dedup_key validation"
  exit 1
}

echo "[OK] B-0303 contract/schema-registry assets are present"
echo "[INFO] run './gradlew :libs:event-core:test' for codec/client tests"
