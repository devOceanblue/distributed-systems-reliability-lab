# E-009 ISR/minISR/acks matrix simulation

## Setup
- RF=3
- Case A: `min.insync.replicas=2`, `acks=all`
- Case B: `min.insync.replicas=1`, `acks=all`

## Run
```bash
./scripts/exp run E-009
./scripts/exp assert E-009
```

## Automated Validation
- Case A:
  - broker 1 down (ISR=2) -> produce success
  - broker 2 down (ISR=1) -> `NotEnoughReplicas`
- Case B:
  - broker 2 down (ISR=1) -> produce success + durability risk flag

Broker chaos helper:
```bash
./scripts/exp broker stop 1
./scripts/exp broker start 1
```
