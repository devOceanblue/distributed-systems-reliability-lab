# E-018 Consumer rebalance storm

## Run
```bash
./scripts/exp run E-018
./scripts/exp assert E-018
```

## Validation
- rebalance/lag/dedup-skip metrics are worse in failure profile
- tuned profile shows improved metrics
