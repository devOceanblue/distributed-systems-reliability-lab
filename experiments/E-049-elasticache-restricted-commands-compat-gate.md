# E-049 ElastiCache Restricted Commands Compatibility Gate

## Goal
ElastiCache에서 제한되는 운영 커맨드 사용을 CI 게이트로 조기 차단한다.

## Run
```bash
./scripts/exp run E-049
./scripts/exp assert E-049
./scripts/verify/E-049.sh
```

## Denylist
- `scripts/compat/elasticache_restricted_commands_denylist.txt`

## Output
- `./.lab/state/e049.stats`
- `./.lab/state/e049/report.md`
