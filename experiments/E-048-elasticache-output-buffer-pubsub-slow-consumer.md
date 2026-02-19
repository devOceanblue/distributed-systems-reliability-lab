# E-048 Pub/Sub Slow Consumer Output Buffer 압박

## Goal
느린 Pub/Sub consumer가 output buffer/메모리/연결 안정성에 주는 악영향을 재현하고 방어책을 검증한다.

## Run
```bash
./scripts/exp run E-048
./scripts/exp assert E-048
```

## Output
- `./.lab/state/e048.stats`
- `./.lab/state/e048/report.md`
