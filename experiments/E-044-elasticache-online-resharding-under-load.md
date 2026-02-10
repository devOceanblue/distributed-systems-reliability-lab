# E-044 ElastiCache Online Resharding/Shard Rebalancing under Load

## Goal
Cluster mode enabled 환경에서 온라인 리샤딩/리밸런싱 중 지연/오류/리다이렉션 변화량을 계량하고 운영 템플릿을 확정한다.

## Managed-service constraints
- ElastiCache는 운영 중 슬롯 이동(온라인 리샤딩/리밸런싱)을 지원한다.
- 판단은 Redis INFO 단독이 아니라 CloudWatch 지표 중심으로 수행한다.

## Run
```bash
./scripts/exp run E-044
./scripts/exp assert E-044
```

## Metrics
- p95/p99 latency, timeout/retry, throughput/error
- MOVED/ASK 비율
- CloudWatch: EngineCPUUtilization, CurrConnections, FreeableMemory, Evictions, NetworkBytesIn/Out, (가능시)ReplicationLag

## Output
- `./.lab/state/e044.stats`
- `./.lab/state/e044/report.md`
