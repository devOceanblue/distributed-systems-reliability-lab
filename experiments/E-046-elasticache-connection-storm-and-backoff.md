# E-046 Connection Storm / Reconnect Thundering Herd

## Goal
Failover/네트워크 블립에서 동시 reconnect 폭주를 재현하고 방어책(backoff+jitter/warmup/circuit breaker) 효과를 계량한다.

## Run
```bash
./scripts/exp run E-046
./scripts/exp assert E-046
```

## Metrics
- CurrConnections, retry rate, connect p99, error rate
- CloudWatch 공통 지표 세트

## Output
- `./.lab/state/e046.stats`
- `./.lab/state/e046/report.md`
