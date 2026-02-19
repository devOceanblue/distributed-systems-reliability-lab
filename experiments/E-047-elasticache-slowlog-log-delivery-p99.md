# E-047 Slow Log + Log Delivery로 p99 원인 규명

## Goal
p99 latency 상승 시 Slow log + 로그 전달(CloudWatch Logs) 기반 진단 루틴을 표준화한다.

## Run
```bash
./scripts/exp run E-047
./scripts/exp assert E-047
```

## Output
- `./.lab/state/e047.stats`
- `./.lab/state/e047/report.md`
