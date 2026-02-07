# command-service

Spring Boot command application for Phase 1 runtime path.

## Endpoints
- `POST /accounts/{id}/deposit`
- `POST /accounts/{id}/withdraw`

Request:
```json
{
  "txId": "tx-1",
  "amount": 100,
  "traceId": "trace-1"
}
```

## Produce Modes
- `PRODUCE_MODE=OUTBOX` (default): domain + ledger + outbox in one DB transaction
- `PRODUCE_MODE=DIRECT`: domain + ledger commit first, then publish

## Failpoint
- `FAILPOINT_AFTER_DB_COMMIT_BEFORE_KAFKA_SEND=true`

## Runtime
```bash
./gradlew :services:command-service:bootRun
```

MySQL ENV:
- `MYSQL_URL`
- `MYSQL_USER`
- `MYSQL_PASSWORD`
