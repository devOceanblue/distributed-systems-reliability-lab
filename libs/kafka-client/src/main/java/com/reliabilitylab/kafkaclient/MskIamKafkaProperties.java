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
}
