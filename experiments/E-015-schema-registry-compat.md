# E-015 Schema Registry compatibility gate

## Run
```bash
./scripts/exp run E-015
./scripts/exp assert E-015
```

## Validation
- additive schema registration succeeds
- breaking schema registration is blocked
