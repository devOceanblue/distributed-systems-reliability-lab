# E-008 Cache stampede simulation

## Setup
- failure: cache off path
- success: cache on path

## Run
```bash
./scripts/exp run E-008
./scripts/exp assert E-008
```

## Automated Validation
- DB read count in failure variant is higher than success variant
