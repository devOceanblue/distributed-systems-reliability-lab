# E-005 Success: Retry -> DLQ -> Replay

## Setup
- `FORCE_PERMANENT_ERROR_ON_ACCOUNT_ID=A-3`
- replay filter: `REPLAY_ACCOUNT_ID=A-3`

Runtime replay-worker 예시:
```bash
./gradlew :services:replay-worker:bootRun
curl -X POST 'http://localhost:8084/internal/replay/run' \
  -H 'content-type: application/json' \
  -d '{"accountIdFrom":"A-3","accountIdTo":"A-3","output":"MAIN","dryRun":false,"rateLimitPerSecond":10,"operatorName":"lab"}'
```

## Run
```bash
./scripts/exp run E-005
./scripts/exp assert E-005
```

## Automated Validation
- replay audit records are written
- projection converges after replay
- dedup prevents side-effect duplication
