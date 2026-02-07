package com.reliabilitylab.eventcore;

public record EventEnvelope(
        String eventId,
        String dedupKey,
        String eventType,
        int schemaVersion,
        long occurredAt,
        String traceId,
        String payloadJson
) {
}
