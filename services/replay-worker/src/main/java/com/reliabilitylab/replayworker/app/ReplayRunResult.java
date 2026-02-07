package com.reliabilitylab.replayworker.app;

public record ReplayRunResult(
        int scanned,
        int replayed,
        int skippedMissingDedup,
        int dryRunCount,
        String outputTopic
) {
}
