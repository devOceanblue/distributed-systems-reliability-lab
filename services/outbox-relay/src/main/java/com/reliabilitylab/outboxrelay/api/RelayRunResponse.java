package com.reliabilitylab.outboxrelay.api;

public record RelayRunResponse(
        boolean processed,
        String state,
        long outboxId,
        String dedupKey
) {
}
