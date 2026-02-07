# E-018 Consumer rebalance storm

## Run
```bash
./scripts/exp run E-018
./scripts/exp assert E-018
```

## Validation
- failure profile(`max.poll.interval=3s`, `max.poll.records=500`)에서 rebalance/lag/dedup-skip가 악화
- tuned profile(`max.poll.interval=60s`, `max.poll.records=50`)에서 동일 부하 대비 지표가 개선
