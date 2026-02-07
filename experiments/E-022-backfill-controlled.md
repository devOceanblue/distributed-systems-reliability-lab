# E-022 Controlled backfill vs unsafe backfill

## Run
```bash
./scripts/exp run E-022
./scripts/exp assert E-022
```

## Validation
- unsafe 모드에서 처리량 대비 lag가 커지고 DB QPS가 높다
- safe 모드는 canary+checkpoint+resume로 전체를 완주한다(`resume_supported=1`)
- source/safe 합계 검증(`sampling_validation_passed=1`)으로 정합성 확인
