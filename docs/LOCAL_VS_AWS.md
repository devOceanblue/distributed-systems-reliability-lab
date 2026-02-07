# LOCAL_VS_AWS

## Local
```bash
make up-local
```

## AWS profile (app only)
```bash
export LAB_PROFILE=aws
export SPRING_PROFILES_ACTIVE=aws
export AWS_PROFILE=dev
export KAFKA_BOOTSTRAP_SERVERS='b-1:9098,b-2:9098,b-3:9098'
export KAFKA_SECURITY_PROTOCOL=SASL_SSL
export KAFKA_SASL_MECHANISM=AWS_MSK_IAM
make up-aws
```

## Switch Principle
Same app binary, profile/env only switches infra target.

## Down
```bash
make down-local
make down-aws
```
