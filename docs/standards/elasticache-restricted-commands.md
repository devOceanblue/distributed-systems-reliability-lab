# ElastiCache Restricted Commands 가드레일

관리형 ElastiCache에서는 다음 운영 커맨드를 애플리케이션 코드에서 사용하지 않는다.

- CONFIG
- BGSAVE
- BGREWRITEAOF
- MIGRATE
- SHUTDOWN

## CI Gate
- `scripts/verify/E-049.sh`
- denylist: `scripts/compat/elasticache_restricted_commands_denylist.txt`
