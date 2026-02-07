package com.reliabilitylab.consumerservice.api;

import jakarta.validation.constraints.NotBlank;

public record ConsumeRequest(
        @NotBlank String eventId,
        @NotBlank String dedupKey,
        @NotBlank String eventType,
        @NotBlank String accountId,
        long amount,
        String rawPayload,
        String topic,
        int partition,
        long offset,
        int attempt
) {
}
