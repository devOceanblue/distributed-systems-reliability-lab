#!/usr/bin/env bash
set -euo pipefail

registry_url="${SCHEMA_REGISTRY_URL:-http://localhost:18091}"
export SCHEMA_REGISTRY_URL="$registry_url"

./infra/schema/register.sh event-envelope-value contracts/avro/event-envelope.avsc
./infra/schema/register.sh account.balance.v1-value contracts/avro/account-balance-changed-v1.avsc

echo "[OK] core schemas registered"
