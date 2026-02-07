package com.reliabilitylab.outboxrelay.app;

public record RelayRunResult(
        boolean processed,
        String state,
        long outboxId,
        String dedupKey
) {
    public static RelayRunResult idle() {
        return new RelayRunResult(false, "IDLE", -1, null);
    }

    public static RelayRunResult sent(OutboxEventRow row) {
        return new RelayRunResult(true, "SENT", row.id(), row.dedupKey());
    }
}
