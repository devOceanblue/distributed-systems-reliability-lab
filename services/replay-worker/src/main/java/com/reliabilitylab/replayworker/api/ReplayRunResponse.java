package com.reliabilitylab.replayworker.api;

public record ReplayRunResponse(
        int scanned,
        int replayed,
        int skippedMissingDedup,
        int dryRunCount,
        String outputTopic
) {
}
