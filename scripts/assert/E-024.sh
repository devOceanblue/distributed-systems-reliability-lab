#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="$ROOT_DIR/.lab/state/e024.stats"

[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
source "$STATS_FILE"

assert_case() {
  local variant="$1"
  local label="$2"
  local quota_var="${variant}_${label}_quota"
  local success_var="${variant}_${label}_success"
  local oversell_var="${variant}_${label}_oversell"
  local duplicate_var="${variant}_${label}_duplicate_blocked"
  local soldout_var="${variant}_${label}_soldout_blocked"

  local quota="${!quota_var}"
  local success="${!success_var}"
  local oversell="${!oversell_var}"
  local duplicate_blocked="${!duplicate_var}"
  local soldout_blocked="${!soldout_var}"

  (( success == quota )) || { echo "${variant} ${label}: success must equal quota"; exit 1; }
  (( oversell == 0 )) || { echo "${variant} ${label}: oversell must be zero"; exit 1; }
  (( duplicate_blocked > 0 )) || { echo "${variant} ${label}: duplicate must be blocked"; exit 1; }
  (( soldout_blocked > 0 )) || { echo "${variant} ${label}: soldout must be blocked"; exit 1; }
}

assert_case mysql 30k
assert_case redis 30k
assert_case mysql 100k
assert_case redis 100k

(( mysql_30k_duration_s == 11 )) || { echo "mysql 30k duration must be 11s"; exit 1; }
(( redis_30k_duration_s == 5 )) || { echo "redis 30k duration must be 5s"; exit 1; }
(( mysql_30k_duration_s > redis_30k_duration_s )) || { echo "30k: mysql should be slower than redis"; exit 1; }
(( mysql_100k_duration_s > redis_100k_duration_s )) || { echo "100k: mysql should be slower than redis"; exit 1; }

mysql_growth=$((mysql_100k_duration_s - mysql_30k_duration_s))
redis_growth=$((redis_100k_duration_s - redis_30k_duration_s))
(( mysql_growth > redis_growth )) || { echo "mysql degradation should be steeper"; exit 1; }

(( mysql_30k_db_gate_ops > redis_30k_db_gate_ops )) || { echo "30k: mysql db gate ops should exceed redis"; exit 1; }
(( mysql_100k_db_gate_ops > redis_100k_db_gate_ops )) || { echo "100k: mysql db gate ops should exceed redis"; exit 1; }
(( mysql_100k_lock_waits > mysql_30k_lock_waits )) || { echo "mysql lock waits should increase at 100k"; exit 1; }
(( redis_100k_redis_cmd_latency_ms >= redis_30k_redis_cmd_latency_ms )) || { echo "redis cmd latency should not decrease at 100k"; exit 1; }

(( mysql_30k_mysql_master_only_required == 1 )) || { echo "mysql should require master-only path"; exit 1; }
(( mysql_100k_mysql_master_only_required == 1 )) || { echo "mysql should require master-only path"; exit 1; }

(( redis_key_init_mismatch_detected == 1 )) || { echo "redis key mismatch should be detected"; exit 1; }
(( redis_key_mismatch_false_soldout == 1 )) || { echo "redis key mismatch should cause false soldout"; exit 1; }
(( redis_key_mismatch_success_count < 10 )) || { echo "mismatch run must reduce successful issues"; exit 1; }

echo "[OK] E-024 assertions passed"
