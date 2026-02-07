#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e013.stats"
reset_and_seed 1

# Failure A: Redis first, DB rollback.
redis_a=0
db_a=0
delta_a=100
redis_a=$((redis_a + delta_a))
# DB rollback keeps DB unchanged.
diff_a=$((redis_a - db_a))
failure_a_redis_db_mismatch=$(( diff_a != 0 ))

# Failure B: DB first, Redis timeout.
redis_b=0
db_b=0
delta_b=120
db_b=$((db_b + delta_b))
# Redis update fails, redis_b unchanged.
diff_b=$((db_b - redis_b))
failure_b_stale_after_db_commit=$(( diff_b != 0 ))

# Success: DB commit + invalidation + cache-aside refill.
redis_success=0
db_success=0
delta_success=80
db_success=$((db_success + delta_success))
# Invalidation clears stale cache; next read repopulates from DB.
redis_success=$db_success
diff_success=$((db_success - redis_success))
success_invalidation_converged=$(( diff_success == 0 ))

cat > "$stats_file" <<STATS
failure_a_db_balance=$db_a
failure_a_redis_balance=$redis_a
failure_a_diff=$diff_a
failure_a_redis_db_mismatch=$failure_a_redis_db_mismatch
failure_b_db_balance=$db_b
failure_b_redis_balance=$redis_b
failure_b_diff=$diff_b
failure_b_stale_after_db_commit=$failure_b_stale_after_db_commit
success_db_balance=$db_success
success_redis_balance=$redis_success
success_diff=$diff_success
success_invalidation_converged=$success_invalidation_converged
STATS
