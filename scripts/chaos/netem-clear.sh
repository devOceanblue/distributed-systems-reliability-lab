#!/usr/bin/env bash
set -euo pipefail

container="${1:-kafka-1}"
compose_file="${COMPOSE_FILE:-docker-compose.local.yml}"

container_id=$(docker compose -f "$compose_file" ps -q "$container")
if [[ -z "$container_id" ]]; then
  echo "container not found: $container" >&2
  exit 1
fi

docker exec "$container_id" tc qdisc del dev eth0 root || true
echo "[OK] netem cleared for $container"
