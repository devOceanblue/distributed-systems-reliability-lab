# E-003 Failure: duplicate side-effect without processed_event

## Setup
- relay failpoint: `FAILPOINT_AFTER_KAFKA_SEND_BEFORE_MARK_SENT=true`
- consumer: `IDEMPOTENCY_MODE=none`

## Run
```bash
./scripts/exp run E-003
./scripts/exp assert E-003
```

## Automated Validation
- `ledger` has one row
- projection is updated twice (`200`)
