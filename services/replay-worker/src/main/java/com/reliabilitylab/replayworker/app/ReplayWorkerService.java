package com.reliabilitylab.replayworker.app;

import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ReplayWorkerService {
    private final DlqEventStore dlqEventStore;
    private final DlqReplayPublisher dlqReplayPublisher;

    public ReplayWorkerService(DlqEventStore dlqEventStore,
                               DlqReplayPublisher dlqReplayPublisher) {
        this.dlqEventStore = dlqEventStore;
        this.dlqReplayPublisher = dlqReplayPublisher;
    }

    public ReplayRunResult run(ReplayRunCommand command) {
        List<DlqEvent> events = dlqEventStore.findPending(command);

        int scanned = 0;
        int replayed = 0;
        int skippedMissingDedup = 0;
        int dryRunCount = 0;

        long intervalMillis = command.rateLimitPerSecond() <= 0
                ? 0
                : Math.max(1L, 1000L / command.rateLimitPerSecond());
        long lastReplayAt = 0L;

        for (DlqEvent event : events) {
            scanned++;
            if (event.dedupKey() == null || event.dedupKey().isBlank()) {
                dlqEventStore.markSkipped(event.id(), "missing dedup_key");
                skippedMissingDedup++;
                continue;
            }

            if (command.dryRun()) {
                dryRunCount++;
                continue;
            }

            sleepToRespectRateLimit(intervalMillis, lastReplayAt);
            dlqReplayPublisher.publish(event, command.outputTopic());
            dlqEventStore.insertReplayAudit(event.dedupKey(), command.operatorName(), command.notes());
            dlqEventStore.markReplayed(event.id());
            replayed++;
            lastReplayAt = System.currentTimeMillis();
        }

        return new ReplayRunResult(scanned, replayed, skippedMissingDedup, dryRunCount, command.outputTopic());
    }

    public void ingest(CapturedDlqEvent event) {
        dlqEventStore.insertCapturedEvent(event);
    }

    private void sleepToRespectRateLimit(long intervalMillis, long lastReplayAt) {
        if (intervalMillis <= 0 || lastReplayAt == 0L) {
            return;
        }
        long elapsed = System.currentTimeMillis() - lastReplayAt;
        long sleepMillis = intervalMillis - elapsed;
        if (sleepMillis <= 0) {
            return;
        }
        try {
            Thread.sleep(sleepMillis);
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
        }
    }
}
