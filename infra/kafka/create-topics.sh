#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_SERVERS=${BOOTSTRAP_SERVERS:-"localhost:19092,localhost:29092,localhost:39092"}

create_topic() {
  local name=$1
  local partitions=$2
  local rf=$3
  echo "Creating topic: ${name}"
  kafka-topics --bootstrap-server "${BOOTSTRAP_SERVERS}" \
    --create \
    --if-not-exists \
    --topic "${name}" \
    --partitions "${partitions}" \
    --replication-factor "${rf}"
}

create_topic account.balance.v1 3 3
create_topic account.balance.retry.5s 3 3
create_topic account.balance.retry.1m 3 3
create_topic account.balance.dlq 3 3
