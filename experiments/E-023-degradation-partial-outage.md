# E-023 Partial outage degradation

## Run
```bash
./scripts/exp run E-023
./scripts/exp assert E-023
```

## Validation
- safe mode lowers error rate vs unsafe in Redis/Kafka/MySQL outage profiles
- Kafka safe mode에서 outbox backlog가 복구 후 소거됨
- Redis safe mode에서 stale serve로 read availability 유지(`stale_serve_kept_reads=1`)
