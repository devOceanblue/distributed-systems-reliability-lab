package com.reliabilitylab.consumerservice.app;

public enum ProcessOutcome {
    PROCESSED,
    DUPLICATE_SKIPPED,
    DLQ,
    RETRY
}
