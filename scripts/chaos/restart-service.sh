#!/usr/bin/env bash
set -euo pipefail

service_script="${1:-services/consumer-service/bin/consumer-service.sh}"

nohup "$service_script" >/tmp/reliability-lab-service.log 2>&1 &
echo "[OK] restarted: $service_script"
