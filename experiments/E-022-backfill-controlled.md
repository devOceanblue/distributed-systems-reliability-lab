# E-022 Controlled backfill vs unsafe backfill

## Run
```bash
./scripts/exp run E-022
./scripts/exp assert E-022
```

## Validation
- unsafe mode has higher DB QPS and lag
- safe mode supports resume and sampling validation
