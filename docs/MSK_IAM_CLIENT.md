# MSK IAM Client

## Java (Spring)
- `security.protocol=SASL_SSL`
- `sasl.mechanism=AWS_MSK_IAM`
- `sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;`
- `sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler`
- 공통 헬퍼: `libs/kafka-client` (`MskIamKafkaProperties.buildFromEnv`)

Dependency:
```gradle
implementation 'software.amazon.msk:aws-msk-iam-auth:2.2.0'
```

## Python
- `security_protocol=SASL_SSL`
- `sasl_mechanism=OAUTHBEARER`
- token provider: `aws_msk_iam_sasl_signer`

## Smoke
```bash
LAB_PROFILE=aws KAFKA_BOOTSTRAP_SERVERS='b-1:9098,b-2:9098,b-3:9098' ./scripts/smoke/aws-kafka-produce.sh
./scripts/smoke/aws-kafka-consume.sh
```
