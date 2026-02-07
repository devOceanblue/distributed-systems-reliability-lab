# E-019 MySQL deadlock + retry policy

## Run
```bash
./scripts/exp run E-019
./scripts/exp assert E-019
```

## Validation
- deadlock-as-permanent increases DLQ
- transient retry profile converges
