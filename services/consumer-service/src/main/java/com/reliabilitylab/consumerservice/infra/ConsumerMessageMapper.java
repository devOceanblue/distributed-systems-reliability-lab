package com.reliabilitylab.consumerservice.infra;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.reliabilitylab.consumerservice.app.ProcessingInput;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.stereotype.Component;

@Component
public class ConsumerMessageMapper {
    private final ObjectMapper objectMapper;

    public ConsumerMessageMapper(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public ProcessingInput fromRecord(ConsumerRecord<String, String> record) {
        try {
            JsonNode root = objectMapper.readTree(record.value());
            JsonNode payloadNode = root.get("payload");

            String eventId = text(root, "event_id", text(root, "eventId", ""));
            String dedupKey = text(root, "dedup_key", text(root, "dedupKey", ""));
            String eventType = text(root, "event_type", text(root, "eventType", ""));
            String accountId = text(payloadNode, "accountId", text(payloadNode, "account_id", ""));
            long amount = longValue(payloadNode, "amount");

            return new ProcessingInput(
                    eventId,
                    dedupKey,
                    eventType,
                    accountId,
                    amount,
                    payloadNode == null ? "{}" : payloadNode.toString(),
                    record.topic(),
                    record.partition(),
                    record.offset(),
                    0
            );
        } catch (Exception e) {
            throw new IllegalArgumentException("failed to parse consumer record", e);
        }
    }

    private String text(JsonNode root, String field, String fallback) {
        if (root == null) {
            return fallback;
        }
        JsonNode value = root.get(field);
        if (value == null || value.isNull()) {
            return fallback;
        }
        return value.asText();
    }

    private long longValue(JsonNode root, String field) {
        if (root == null) {
            return 0L;
        }
        JsonNode value = root.get(field);
        if (value == null || value.isNull()) {
            return 0L;
        }
        return value.asLong();
    }
}
