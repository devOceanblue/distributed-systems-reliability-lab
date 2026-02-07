package com.reliabilitylab.kafkaclient;

import java.util.HashMap;
import java.util.Map;

public final class MskIamKafkaProperties {
    private MskIamKafkaProperties() {
    }

    public static Map<String, Object> build(String bootstrapServers) {
        Map<String, Object> properties = new HashMap<>();
        properties.put("bootstrap.servers", bootstrapServers);
        properties.put("security.protocol", "SASL_SSL");
        properties.put("sasl.mechanism", "AWS_MSK_IAM");
        properties.put("sasl.jaas.config", "software.amazon.msk.auth.iam.IAMLoginModule required;");
        properties.put("sasl.client.callback.handler.class", "software.amazon.msk.auth.iam.IAMClientCallbackHandler");
        return properties;
    }

    public static Map<String, Object> buildFromEnv(Map<String, String> env) {
        String bootstrap = env.getOrDefault("KAFKA_BOOTSTRAP_SERVERS", "");
        Map<String, Object> properties = build(bootstrap);
        properties.put("security.protocol", env.getOrDefault("KAFKA_SECURITY_PROTOCOL", "SASL_SSL"));
        properties.put("sasl.mechanism", env.getOrDefault("KAFKA_SASL_MECHANISM", "AWS_MSK_IAM"));
        properties.put(
                "sasl.jaas.config",
                env.getOrDefault("KAFKA_SASL_JAAS_CONFIG", "software.amazon.msk.auth.iam.IAMLoginModule required;")
        );
        properties.put(
                "sasl.client.callback.handler.class",
                env.getOrDefault(
                        "KAFKA_SASL_CALLBACK_HANDLER",
                        "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
                )
        );
        return properties;
    }
}
