# E-014 processed_event retention strategy

## Run
```bash
./scripts/exp run E-014
./scripts/exp assert E-014
```

## Validation
- baseline row/bytes > post-retention row/bytes
- purge 후 insert p95(`insert_p95_before_ms` vs `insert_p95_after_ms`) 개선
- archive partition drop 시 제거 행 수(`partition_drop_removed`) 확인
