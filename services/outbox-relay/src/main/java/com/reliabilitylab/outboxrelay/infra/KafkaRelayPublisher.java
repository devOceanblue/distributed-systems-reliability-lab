package com.reliabilitylab.outboxrelay.infra;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.reliabilitylab.outboxrelay.app.OutboxEventRow;
import com.reliabilitylab.outboxrelay.app.RelayPublisher;
import com.reliabilitylab.outboxrelay.config.TopicProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

@Component
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "true")
public class KafkaRelayPublisher implements RelayPublisher {
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final TopicProperties topicProperties;
    private final ObjectMapper objectMapper;

    public KafkaRelayPublisher(KafkaTemplate<String, String> kafkaTemplate,
                               TopicProperties topicProperties,
                               ObjectMapper objectMapper) {
        this.kafkaTemplate = kafkaTemplate;
        this.topicProperties = topicProperties;
        this.objectMapper = objectMapper;
    }

    @Override
    public void publish(OutboxEventRow row) {
        String key = extractAccountId(row.payloadJson());
        String value = serializeEnvelope(row);
        kafkaTemplate.send(topicProperties.getAccountBalance(), key, value);
    }

    private String extractAccountId(String payloadJson) {
        try {
            JsonNode payload = objectMapper.readTree(payloadJson);
            JsonNode accountId = payload.get("accountId");
            if (accountId == null || accountId.isNull()) {
                return "unknown-account";
            }
            return accountId.asText();
        } catch (JsonProcessingException e) {
            return "unknown-account";
        }
    }

    private String serializeEnvelope(OutboxEventRow row) {
        try {
            Map<String, Object> envelope = new LinkedHashMap<>();
            envelope.put("event_id", row.eventId());
            envelope.put("dedup_key", row.dedupKey());
            envelope.put("event_type", row.eventType());
            envelope.put("schema_version", 1);
            envelope.put("occurred_at", System.currentTimeMillis());
            envelope.put("trace_id", null);
            envelope.put("payload", objectMapper.readTree(row.payloadJson()));
            return objectMapper.writeValueAsString(envelope);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("failed to serialize relay envelope", e);
        }
    }
}
