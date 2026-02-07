# E-008 Cache stampede simulation

## Setup
- failure: cache off path
- success: cache on path

Runtime 체크(선택):
```bash
APP_REDIS_ENABLED=true STAMPEDE_PROTECTION=OFF ./gradlew :services:query-service:bootRun
APP_REDIS_ENABLED=true CACHE_INVALIDATION_MODE=VERSIONED ./gradlew :services:consumer-service:bootRun
```

## Run
```bash
./scripts/exp run E-008
./scripts/exp assert E-008
```

## Automated Validation
- DB read count in failure variant is higher than success variant
- `services/query-service` 테스트에서 stampede ON/OFF DB read 차이를 자동 assert
