#!/usr/bin/env bash
set -euo pipefail

container="${1:-kafka-1}"
delay_ms="${2:-200}"
loss_pct="${3:-0}"
compose_file="${COMPOSE_FILE:-docker-compose.local.yml}"

container_id=$(docker compose -f "$compose_file" ps -q "$container")
if [[ -z "$container_id" ]]; then
  echo "container not found: $container" >&2
  exit 1
fi

docker exec "$container_id" tc qdisc replace dev eth0 root netem delay "${delay_ms}ms" loss "${loss_pct}%"
echo "[OK] netem applied to $container (${delay_ms}ms, loss ${loss_pct}%)"
