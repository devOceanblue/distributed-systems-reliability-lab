# consumer-service

Spring Boot consumer runtime with idempotency, retry, DLQ, and offset policy toggles.

## Core
- idempotency with `processed_event`
- projection update on `account_projection`
- offset policy: `AFTER_DB` or `BEFORE_DB`
- permanent error -> DLQ
- transient error -> retry topic

## Toggles
- `IDEMPOTENCY_MODE=PROCESSED_TABLE|NONE`
- `OFFSET_COMMIT_MODE=AFTER_DB|BEFORE_DB`
- `CACHE_INVALIDATION_MODE=DEL|VERSIONED|NONE`
- `APP_REDIS_ENABLED=true|false`
- `FAILPOINT_AFTER_OFFSET_COMMIT_BEFORE_DB_COMMIT=true`
- `FORCE_PERMANENT_ERROR_ON_ACCOUNT_ID=A-3`

## Run
```bash
./gradlew :services:consumer-service:bootRun
```

## Deterministic Trigger
```bash
curl -X POST 'http://localhost:8082/internal/consumer/process' \
  -H 'content-type: application/json' \
  -d '{"eventId":"evt-1","dedupKey":"tx-1","eventType":"AccountBalanceChanged","accountId":"A-1","amount":100}'
```
