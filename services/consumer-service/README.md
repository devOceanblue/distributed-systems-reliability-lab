# consumer-service

Deterministic consumer simulator with idempotency/retry policy toggles.

## Toggles
- `IDEMPOTENCY_MODE=processed_table|none`
- `OFFSET_COMMIT_MODE=after_db|before_db`
- `FAILPOINT_AFTER_OFFSET_COMMIT_BEFORE_DB_COMMIT=true`
- `FORCE_PERMANENT_ERROR_ON_ACCOUNT_ID=A-3`

## Usage
```bash
services/consumer-service/bin/consumer-service.sh
```
