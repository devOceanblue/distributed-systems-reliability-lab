# LOCAL_VS_AWS

## Local
```bash
make up-local
```

## AWS profile (app only)
```bash
export LAB_PROFILE=aws
export AWS_PROFILE=dev
export KAFKA_BOOTSTRAP_SERVERS='b-1:9098,b-2:9098,b-3:9098'
make up-aws
```

## Switch Principle
Same app binary, profile/env only switches infra target.
