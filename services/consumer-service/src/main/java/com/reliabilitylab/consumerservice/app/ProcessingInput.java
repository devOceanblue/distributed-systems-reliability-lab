package com.reliabilitylab.consumerservice.app;

public record ProcessingInput(
        String eventId,
        String dedupKey,
        String eventType,
        String accountId,
        long amount,
        String rawPayload,
        String topic,
        int partition,
        long offset,
        int attempt
) {
}
