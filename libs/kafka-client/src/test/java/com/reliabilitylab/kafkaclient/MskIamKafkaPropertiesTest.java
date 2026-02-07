package com.reliabilitylab.kafkaclient;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

class MskIamKafkaPropertiesTest {

    @Test
    void shouldBuildDefaultIamProperties() {
        Map<String, Object> properties = MskIamKafkaProperties.build("b-1.dev:9098");

        assertEquals("b-1.dev:9098", properties.get("bootstrap.servers"));
        assertEquals("SASL_SSL", properties.get("security.protocol"));
        assertEquals("AWS_MSK_IAM", properties.get("sasl.mechanism"));
        assertEquals("software.amazon.msk.auth.iam.IAMLoginModule required;", properties.get("sasl.jaas.config"));
        assertEquals("software.amazon.msk.auth.iam.IAMClientCallbackHandler", properties.get("sasl.client.callback.handler.class"));
    }

    @Test
    void shouldRespectEnvOverrides() {
        Map<String, String> env = Map.of(
                "KAFKA_BOOTSTRAP_SERVERS", "b-1.dev:9098,b-2.dev:9098",
                "KAFKA_SECURITY_PROTOCOL", "SASL_SSL",
                "KAFKA_SASL_MECHANISM", "AWS_MSK_IAM",
                "KAFKA_SASL_JAAS_CONFIG", "custom-jaas;",
                "KAFKA_SASL_CALLBACK_HANDLER", "custom.handler.Class"
        );

        Map<String, Object> properties = MskIamKafkaProperties.buildFromEnv(env);

        assertEquals("b-1.dev:9098,b-2.dev:9098", properties.get("bootstrap.servers"));
        assertEquals("custom-jaas;", properties.get("sasl.jaas.config"));
        assertEquals("custom.handler.Class", properties.get("sasl.client.callback.handler.class"));
    }
}
