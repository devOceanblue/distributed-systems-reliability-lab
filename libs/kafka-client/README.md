# kafka-client (MSK IAM profile helper)

Provides profile-specific Kafka client properties for local/AWS runs.

## Usage
```java
Map<String, Object> props = MskIamKafkaProperties.buildFromEnv(System.getenv());
```

Default profile values:
- `security.protocol=SASL_SSL`
- `sasl.mechanism=AWS_MSK_IAM`
- `sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;`
- `sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler`
