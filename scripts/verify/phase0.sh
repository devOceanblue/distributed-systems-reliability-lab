#!/usr/bin/env bash
set -euo pipefail

required_files=(
  docker-compose.local.yml
  docker-compose.aws.override.yml
  infra/kafka/create-topics.sh
  infra/mysql/init.sql
  infra/redis/redis.conf
  docs/ENV_CONTRACT.md
  contracts/avro/event-envelope.avsc
  contracts/avro/account-balance-changed-v1.avsc
  libs/event-core/src/main/java/com/reliabilitylab/eventcore/EventEnvelope.java
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "[FAIL] missing: $file"
    exit 1
  fi
done

if ! rg -q "dedup_key" contracts/avro/event-envelope.avsc; then
  echo "[FAIL] envelope schema does not include dedup_key"
  exit 1
fi

if ! test -x infra/kafka/create-topics.sh; then
  echo "[FAIL] infra/kafka/create-topics.sh is not executable"
  exit 1
fi

echo "[OK] phase0 bootstrap assets are present"
