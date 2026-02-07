# E-013 Redis Lua consistency anti-pattern

## Run
```bash
./scripts/exp run E-013
./scripts/exp assert E-013
```

## Validation
- Redis-first + DB rollback mismatch marker
- DB-first + Redis failure stale marker
- invalidation-based convergence marker
