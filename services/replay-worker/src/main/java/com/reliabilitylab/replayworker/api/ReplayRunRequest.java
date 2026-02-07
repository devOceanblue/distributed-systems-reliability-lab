package com.reliabilitylab.replayworker.api;

import jakarta.validation.constraints.Min;

public record ReplayRunRequest(
        String accountIdFrom,
        String accountIdTo,
        String eventType,
        Long fromEpochMillis,
        Long toEpochMillis,
        @Min(1) Integer batchSize,
        @Min(1) Integer rateLimitPerSecond,
        Boolean dryRun,
        String output,
        String operatorName,
        String notes
) {
}
