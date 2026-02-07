# E-002 Failure: direct-produce crash after DB commit

## Setup
- `PRODUCE_MODE=direct`
- `FAILPOINT_AFTER_DB_COMMIT_BEFORE_KAFKA_SEND=true`

## Run
```bash
./scripts/exp run E-002
./scripts/exp assert E-002
```

## Automated Validation
- domain balance is updated
- topic has no produced event
- projection remains stale
