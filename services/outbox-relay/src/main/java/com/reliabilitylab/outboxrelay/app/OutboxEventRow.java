package com.reliabilitylab.outboxrelay.app;

public record OutboxEventRow(
        long id,
        String eventId,
        String dedupKey,
        String eventType,
        String payloadJson,
        int attempts
) {
}
