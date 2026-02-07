# outbox-relay

Deterministic outbox relay simulator.

## Failpoints
- `FAILPOINT_AFTER_KAFKA_SEND_BEFORE_MARK_SENT=true`
- `FAILPOINT_BEFORE_KAFKA_SEND=true`

## Usage
```bash
services/outbox-relay/bin/outbox-relay.sh
```
