# E-019 MySQL deadlock + retry policy

## Run
```bash
./scripts/exp run E-019
./scripts/exp assert E-019
```

## Validation
- deadlock를 permanent로 분류한 실패 프로필에서 DLQ가 크게 증가
- deadlock를 transient retry로 분류한 성공 프로필에서 DLQ가 감소하고 최종 수렴
- `retry_attempt_count`로 retry 경로가 실제 실행됐는지 확인
