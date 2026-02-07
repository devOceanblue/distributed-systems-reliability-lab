# command-service

Deterministic command path simulator.

## Modes
- `PRODUCE_MODE=outbox` (default)
- `PRODUCE_MODE=direct`

## Failpoint
- `FAILPOINT_AFTER_DB_COMMIT_BEFORE_KAFKA_SEND=true`

## Usage
```bash
services/command-service/bin/command-service.sh deposit A-1 tx-1 100
services/command-service/bin/command-service.sh withdraw A-1 tx-2 40
```
