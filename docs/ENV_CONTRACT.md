# ENV Contract

## Profile
- `LAB_PROFILE`: `local` or `aws`

## Kafka
- `KAFKA_BOOTSTRAP_SERVERS`
- `KAFKA_SECURITY_PROTOCOL`: `PLAINTEXT` or `SASL_SSL`
- `KAFKA_SASL_MECHANISM`: `AWS_MSK_IAM` / `OAUTHBEARER` / empty
- `KAFKA_SASL_JAAS_CONFIG`
- `KAFKA_SASL_CALLBACK_HANDLER`
- `KAFKA_CLIENT_RACK` (optional)

## MySQL
- `MYSQL_URL`
- `MYSQL_USER`
- `MYSQL_PASSWORD`

## Redis
- `REDIS_HOST`
- `REDIS_PORT`

## AWS
- `AWS_REGION`
- `AWS_PROFILE`

## Local Example
```bash
export LAB_PROFILE=local
export KAFKA_BOOTSTRAP_SERVERS=localhost:19192,localhost:29192,localhost:39192
export KAFKA_SECURITY_PROTOCOL=PLAINTEXT
export MYSQL_URL=jdbc:mysql://localhost:13306/lab
export MYSQL_USER=lab
export MYSQL_PASSWORD=lab
export REDIS_HOST=localhost
export REDIS_PORT=16379
```

## AWS Example
```bash
export LAB_PROFILE=aws
export KAFKA_BOOTSTRAP_SERVERS=b-1.msk.dev:9098,b-2.msk.dev:9098,b-3.msk.dev:9098
export KAFKA_SECURITY_PROTOCOL=SASL_SSL
export KAFKA_SASL_MECHANISM=AWS_MSK_IAM
export KAFKA_SASL_JAAS_CONFIG='software.amazon.msk.auth.iam.IAMLoginModule required;'
export KAFKA_SASL_CALLBACK_HANDLER=software.amazon.msk.auth.iam.IAMClientCallbackHandler
export MYSQL_URL=jdbc:mysql://aurora.dev:3306/lab
export MYSQL_USER=lab
export MYSQL_PASSWORD=***
export REDIS_HOST=elasticache.dev
export REDIS_PORT=6379
export AWS_REGION=us-east-1
export AWS_PROFILE=dev
```
