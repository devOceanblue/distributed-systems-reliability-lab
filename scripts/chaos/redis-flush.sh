#!/usr/bin/env bash
set -euo pipefail

host="${REDIS_HOST:-127.0.0.1}"
port="${REDIS_PORT:-16379}"

redis-cli -h "$host" -p "$port" FLUSHALL
echo "[OK] redis flushed"
