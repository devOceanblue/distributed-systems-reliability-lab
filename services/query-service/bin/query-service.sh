#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"

cache_ttl_seconds="${TTL_SECONDS:-30}"
cache_mode="${CACHE_INVALIDATION_MODE:-DEL}"

"$SIM" query "$1" "$cache_ttl_seconds" "$cache_mode"
