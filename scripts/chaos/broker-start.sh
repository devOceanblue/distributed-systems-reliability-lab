#!/usr/bin/env bash
set -euo pipefail

broker_id="${1:-1}"
compose_file="${COMPOSE_FILE:-docker-compose.local.yml}"

docker compose -f "$compose_file" start "kafka-${broker_id}"
echo "[OK] kafka-${broker_id} started"
