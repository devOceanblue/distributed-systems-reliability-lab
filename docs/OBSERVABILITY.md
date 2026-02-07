# OBSERVABILITY (AWS)

Core signals for AWS runs:
- consumer lag
- outbox oldest age
- dlq rate
- aurora qps/deadlock
- redis hit/miss/evictions

Dashboard source:
- `dashboards/aws-reliability-overview.json`

Alarm policy should gate degraded mode switch and operator response.
