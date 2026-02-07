package com.reliabilitylab.replayworker.infra;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.reliabilitylab.replayworker.app.CapturedDlqEvent;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.UUID;

@Component
public class DlqMessageMapper {
    private final ObjectMapper objectMapper;

    public DlqMessageMapper(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public CapturedDlqEvent fromRawMessage(String value) {
        try {
            JsonNode root = objectMapper.readTree(value);
            JsonNode payload = root.path("payload");

            String eventId = text(root, "eventId",
                    text(root, "event_id", "dlq-" + UUID.randomUUID()));
            String dedupKey = text(root, "dedupKey", text(root, "dedup_key", ""));
            String eventType = text(root, "eventType", text(root, "event_type", ""));
            String accountId = text(root, "accountId",
                    text(root, "account_id",
                            text(payload, "accountId", text(payload, "account_id", ""))));
            long amount = longValue(root, "amount", longValue(payload, "amount", 0L));
            int attempt = (int) longValue(root, "attempt", 0L);
            long occurredAtMillis = longValue(root, "occurredAt",
                    longValue(root, "occurred_at", Instant.now().toEpochMilli()));

            return new CapturedDlqEvent(
                    eventId,
                    dedupKey,
                    eventType,
                    accountId,
                    amount,
                    attempt,
                    Instant.ofEpochMilli(occurredAtMillis),
                    value
            );
        } catch (Exception ex) {
            throw new IllegalArgumentException("failed to parse DLQ message", ex);
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

    private long longValue(JsonNode root, String field, long fallback) {
        if (root == null) {
            return fallback;
        }
        JsonNode value = root.get(field);
        if (value == null || value.isNull()) {
            return fallback;
        }
        return value.asLong();
    }
}
