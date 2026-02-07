# E-011 Hot key/hot shard experiment

## Run
```bash
./scripts/exp run E-011
./scripts/exp assert E-011
```

## Validation
- hot key profile(`failure_unique_keys=1`)에서 p95/p99가 분산 키 프로필보다 높다
- hot key profile에서 DB QPS가 분산 키 프로필보다 높다
