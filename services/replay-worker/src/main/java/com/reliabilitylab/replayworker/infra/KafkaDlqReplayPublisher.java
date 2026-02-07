package com.reliabilitylab.replayworker.infra;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.reliabilitylab.replayworker.app.DlqEvent;
import com.reliabilitylab.replayworker.app.DlqReplayPublisher;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

@Component
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "true")
public class KafkaDlqReplayPublisher implements DlqReplayPublisher {
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    public KafkaDlqReplayPublisher(KafkaTemplate<String, String> kafkaTemplate,
                                   ObjectMapper objectMapper) {
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Override
    public void publish(DlqEvent event, String outputTopic) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("eventId", event.eventId());
        payload.put("dedupKey", event.dedupKey());
        payload.put("eventType", event.eventType());
        payload.put("accountId", event.accountId());
        payload.put("amount", event.amount());
        payload.put("attempt", event.attempt() + 1);
        payload.put("replayedAt", System.currentTimeMillis());

        kafkaTemplate.send(outputTopic, event.accountId(), toJson(payload));
    }

    private String toJson(Map<String, Object> payload) {
        try {
            return objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("failed to serialize replay payload", ex);
        }
    }
}
