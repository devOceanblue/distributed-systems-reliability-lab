#!/usr/bin/env bash
set -euo pipefail

compose_file="${COMPOSE_FILE:-docker-compose.local.yml}"

create_topic() {
  local name="$1"
  local partitions="$2"
  local repl="$3"

  docker compose -f "$compose_file" exec -T kafka-1 \
    kafka-topics --bootstrap-server kafka-1:9092 \
    --create --if-not-exists \
    --topic "$name" \
    --partitions "$partitions" \
    --replication-factor "$repl"
}

create_topic "account.balance.v1" 6 3
create_topic "account.balance.retry.5s" 3 3
create_topic "account.balance.retry.1m" 3 3
create_topic "account.balance.dlq" 3 3
create_topic "account.balance.replay-source" 6 3

echo "[OK] topics ensured"
