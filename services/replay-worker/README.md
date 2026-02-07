# replay-worker

Spring Boot replay runtime for controlled DLQ replay + audit.

## Toggles
- `APP_KAFKA_ENABLED=true|false`
- `REPLAY_BATCH_SIZE=100`
- `REPLAY_RATE_LIMIT_PER_SECOND=10`
- `REPLAY_OUTPUT=MAIN|RETRY5S|RETRY1M`
- `REPLAY_OPERATOR=system`

## Usage
```bash
./gradlew :services:replay-worker:bootRun

curl -X POST 'http://localhost:8084/internal/replay/ingest' \
  -H 'content-type: application/json' \
  -d '{"eventId":"evt-dlq-1","dedupKey":"tx-1","eventType":"AccountBalanceChanged","accountId":"A-1","amount":100,"attempt":1,"occurredAtEpochMillis":1767225600000,"rawPayload":"{\"eventId\":\"evt-dlq-1\"}"}'

curl -X POST 'http://localhost:8084/internal/replay/run' \
  -H 'content-type: application/json' \
  -d '{"output":"MAIN","dryRun":false,"operatorName":"lab"}'
```
