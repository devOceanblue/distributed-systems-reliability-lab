# E-010 Redis Cluster slot/hashtag experiment

## Run
```bash
./scripts/exp run E-010
./scripts/exp assert E-010
```

## Validation
- non-hashtag multi-key pair maps to different slots (`failure_crossslot=1`)
- hashtag pair maps to same slot (`success_hashtag=1`)
- `{hot}` 태그 남발 시 슬롯 집중도(`hot_shard_ratio_pct`)가 높게 관측됨
