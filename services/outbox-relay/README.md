# outbox-relay

Spring Boot relay runtime that publishes `outbox_event` rows to Kafka.

## Core
- poll `NEW` rows
- mark `SENDING`
- publish to topic
- mark `SENT`
- on failure: retry with backoff or move to `FAILED`

## Failpoints
- `FAILPOINT_BEFORE_KAFKA_SEND=true`
- `FAILPOINT_AFTER_KAFKA_SEND_BEFORE_MARK_SENT=true`

## Run
```bash
./gradlew :services:outbox-relay:bootRun
```

## Deterministic Trigger
```bash
curl -X POST 'http://localhost:8081/internal/relay/run-once'
```
