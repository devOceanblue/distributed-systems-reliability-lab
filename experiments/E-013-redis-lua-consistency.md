# E-013 Redis Lua consistency anti-pattern

## Run
```bash
./scripts/exp run E-013
./scripts/exp assert E-013
```

## Validation
- failure A: Redis-first + DB rollback에서 `failure_a_diff != 0`
- failure B: DB-first + Redis timeout에서 `failure_b_diff != 0`
- success: invalidation + cache-aside에서 `success_diff == 0`
