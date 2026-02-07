#!/usr/bin/env bash
set -euo pipefail

service_name="${1:-consumer-service.sh}"
pkill -f "$service_name" || true
echo "[OK] killed process pattern: $service_name"
