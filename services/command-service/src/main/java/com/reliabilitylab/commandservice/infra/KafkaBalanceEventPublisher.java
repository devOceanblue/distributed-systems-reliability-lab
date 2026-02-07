package com.reliabilitylab.commandservice.infra;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.reliabilitylab.commandservice.config.CommandServiceProperties;
import com.reliabilitylab.eventcore.EventEnvelope;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "true")
public class KafkaBalanceEventPublisher implements BalanceEventPublisher {
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;
    private final CommandServiceProperties commandServiceProperties;

    public KafkaBalanceEventPublisher(KafkaTemplate<String, String> kafkaTemplate,
                                      ObjectMapper objectMapper,
                                      CommandServiceProperties commandServiceProperties) {
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
        this.commandServiceProperties = commandServiceProperties;
    }

    @Override
    public void publish(EventEnvelope envelope, String accountId) {
        String payload = toJson(envelope);
        kafkaTemplate.send(commandServiceProperties.getTopic().getAccountBalance(), accountId, payload);
    }

    private String toJson(EventEnvelope envelope) {
        try {
            return objectMapper.writeValueAsString(envelope);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("failed to serialize envelope", e);
        }
    }
}
