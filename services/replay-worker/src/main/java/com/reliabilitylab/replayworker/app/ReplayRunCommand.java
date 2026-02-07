package com.reliabilitylab.replayworker.app;

public record ReplayRunCommand(
        String accountIdFrom,
        String accountIdTo,
        String eventType,
        Long fromEpochMillis,
        Long toEpochMillis,
        int batchSize,
        int rateLimitPerSecond,
        boolean dryRun,
        String outputTopic,
        String operatorName,
        String notes
) {
}
