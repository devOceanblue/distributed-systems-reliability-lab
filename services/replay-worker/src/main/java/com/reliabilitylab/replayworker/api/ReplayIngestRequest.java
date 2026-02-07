package com.reliabilitylab.replayworker.api;

import jakarta.validation.constraints.NotBlank;

public record ReplayIngestRequest(
        String eventId,
        String dedupKey,
        String eventType,
        String accountId,
        long amount,
        int attempt,
        long occurredAtEpochMillis,
        @NotBlank String rawPayload
) {
}
