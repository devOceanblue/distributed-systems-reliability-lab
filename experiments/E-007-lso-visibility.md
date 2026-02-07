# E-007 HW/LEO/LSO visibility simulation

## Setup
- local-only transactional visibility simulation marker

## Run
```bash
./scripts/exp run E-007
./scripts/exp assert E-007
```

## Automated Validation
- read-uncommitted visibility marker present
- read-committed stall marker present
- commit/abort resolution marker present
