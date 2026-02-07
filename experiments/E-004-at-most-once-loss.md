# E-004 Failure: offset commit before DB commit

## Setup
- `OFFSET_COMMIT_MODE=before_db`
- `FAILPOINT_AFTER_OFFSET_COMMIT_BEFORE_DB_COMMIT=true`

## Run
```bash
./scripts/exp run E-004
./scripts/exp assert E-004
```

## Automated Validation
- 10 messages produced
- 9 messages processed
- projection reflects one lost message
