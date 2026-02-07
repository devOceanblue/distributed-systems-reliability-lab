# E-005 Success: Retry -> DLQ -> Replay

## Setup
- `FORCE_PERMANENT_ERROR_ON_ACCOUNT_ID=A-3`
- replay filter: `REPLAY_ACCOUNT_ID=A-3`
- replay는 2회 실행해 duplicate replay를 의도적으로 생성하고 `processed_event`로 무해성 검증

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

런타임 E2E 검증:
```bash
./gradlew :services:e2e-tests:test --tests com.reliabilitylab.e2e.RetryDlqReplayE2ETest
```

## Automated Validation
- replay audit records are written (duplicate replay 포함)
- projection converges after replay
- dedup prevents side-effect duplication
