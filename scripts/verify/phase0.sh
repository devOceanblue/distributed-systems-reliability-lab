#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "docker-compose.yml"
  "infra/kafka/create-topics.sh"
  "infra/mysql/init.sql"
  "infra/redis/redis.conf"
  "contracts/avro/event-envelope.avsc"
  "contracts/avro/account-balance-changed-v1.avsc"
  "libs/event-core/src/main/java/com/reliabilitylab/eventcore/EventEnvelope.java"
  "libs/event-core/src/main/java/com/reliabilitylab/eventcore/Failpoint.java"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "${file}" ]]; then
    echo "Missing required file: ${file}" >&2
    exit 1
  fi
  echo "OK: ${file}"
 done
