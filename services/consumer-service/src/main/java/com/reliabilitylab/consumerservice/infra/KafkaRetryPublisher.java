package com.reliabilitylab.consumerservice.infra;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.reliabilitylab.consumerservice.app.ProcessingInput;
import com.reliabilitylab.consumerservice.app.RetryPublisher;
import com.reliabilitylab.consumerservice.config.ConsumerServiceProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

@Component
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "true")
public class KafkaRetryPublisher implements RetryPublisher {
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ConsumerServiceProperties properties;
    private final ObjectMapper objectMapper;

    public KafkaRetryPublisher(KafkaTemplate<String, String> kafkaTemplate,
                               ConsumerServiceProperties properties,
                               ObjectMapper objectMapper) {
        this.kafkaTemplate = kafkaTemplate;
        this.properties = properties;
        this.objectMapper = objectMapper;
    }

    @Override
    public void publish(ProcessingInput input, Exception exception) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("eventId", input.eventId());
        payload.put("dedupKey", input.dedupKey());
        payload.put("eventType", input.eventType());
        payload.put("accountId", input.accountId());
        payload.put("amount", input.amount());
        payload.put("attempt", input.attempt() + 1);
        payload.put("error", exception.getMessage());

        kafkaTemplate.send(properties.getTopic().getRetry5s(), input.accountId(), toJson(payload));
    }

    private String toJson(Map<String, Object> value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("failed to serialize retry payload", e);
        }
    }
}
