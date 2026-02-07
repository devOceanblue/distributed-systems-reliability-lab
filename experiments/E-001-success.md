# E-001 Success: Outbox + Relay + processed_event + invalidation

## Setup
- `PRODUCE_MODE=outbox`
- `IDEMPOTENCY_MODE=processed_table`
- `CACHE_INVALIDATION_MODE=DEL`

## Run
```bash
./scripts/exp run E-001
./scripts/exp assert E-001
```

## Automated Validation
- `ledger` rows = 1000
- `processed_event` rows = 1000
- all account projections converge to expected balance (`10000`)
