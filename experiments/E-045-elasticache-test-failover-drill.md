# E-045 Multi-AZ Auto-Failover Drill (ElastiCache test-failover)

## Goal
ElastiCache Multi-AZ 자동 장애조치에서 `test-failover` API 표준 절차를 검증한다.

## Run
```bash
./scripts/exp run E-045
./scripts/exp assert E-045
```

## Required metrics
- reconnect seconds/count
- write timeout/error spikes
- p99 latency
- CloudWatch: EngineCPUUtilization, CurrConnections, FreeableMemory, Evictions, NetworkBytesIn/Out, (가능시)ReplicationLag

## Output
- `./.lab/state/e045.stats`
- `./.lab/state/e045/report.md`
