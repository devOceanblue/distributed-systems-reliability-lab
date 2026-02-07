package com.reliabilitylab.replayworker.app;

import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ReplayWorkerServiceTest {

    @Test
    void shouldSkipMissingDedupKeyForSafety() {
        FakeDlqEventStore store = new FakeDlqEventStore();
        store.pending.add(new DlqEvent(1L, "evt-1", "", "AccountBalanceChanged", "A-1", 100, 1, Instant.now(), "{}"));

        FakeReplayPublisher publisher = new FakeReplayPublisher();
        ReplayWorkerService service = new ReplayWorkerService(store, publisher);

        ReplayRunResult result = service.run(command(false));

        assertEquals(1, result.scanned());
        assertEquals(1, result.skippedMissingDedup());
        assertEquals(0, result.replayed());
        assertEquals(0, publisher.published.size());
        assertEquals(List.of(1L), store.skippedIds);
    }

    @Test
    void shouldPublishAndAuditWhenReplayRuns() {
        FakeDlqEventStore store = new FakeDlqEventStore();
        store.pending.add(new DlqEvent(2L, "evt-2", "tx-2", "AccountBalanceChanged", "A-2", 200, 1, Instant.now(), "{}"));

        FakeReplayPublisher publisher = new FakeReplayPublisher();
        ReplayWorkerService service = new ReplayWorkerService(store, publisher);

        ReplayRunResult result = service.run(command(false));

        assertEquals(1, result.scanned());
        assertEquals(1, result.replayed());
        assertEquals(0, result.skippedMissingDedup());
        assertEquals(1, publisher.published.size());
        assertEquals(List.of(2L), store.replayedIds);
        assertEquals(List.of("tx-2"), store.auditDedupKeys);
    }

    @Test
    void shouldCountDryRunWithoutPublishing() {
        FakeDlqEventStore store = new FakeDlqEventStore();
        store.pending.add(new DlqEvent(3L, "evt-3", "tx-3", "AccountBalanceChanged", "A-3", 300, 1, Instant.now(), "{}"));

        FakeReplayPublisher publisher = new FakeReplayPublisher();
        ReplayWorkerService service = new ReplayWorkerService(store, publisher);

        ReplayRunResult result = service.run(command(true));

        assertEquals(1, result.scanned());
        assertEquals(1, result.dryRunCount());
        assertEquals(0, result.replayed());
        assertEquals(0, publisher.published.size());
        assertEquals(0, store.replayedIds.size());
        assertEquals(0, store.auditDedupKeys.size());
    }

    private static ReplayRunCommand command(boolean dryRun) {
        return new ReplayRunCommand(
                null,
                null,
                null,
                null,
                null,
                100,
                1000,
                dryRun,
                "account.balance.v1",
                "tester",
                "test-run"
        );
    }

    private static final class FakeDlqEventStore implements DlqEventStore {
        private final List<DlqEvent> pending = new ArrayList<>();
        private final List<Long> replayedIds = new ArrayList<>();
        private final List<Long> skippedIds = new ArrayList<>();
        private final List<String> auditDedupKeys = new ArrayList<>();

        @Override
        public void insertCapturedEvent(CapturedDlqEvent event) {
        }

        @Override
        public List<DlqEvent> findPending(ReplayRunCommand command) {
            return new ArrayList<>(pending);
        }

        @Override
        public void markReplayed(long id) {
            replayedIds.add(id);
        }

        @Override
        public void markSkipped(long id, String reason) {
            skippedIds.add(id);
        }

        @Override
        public void insertReplayAudit(String dedupKey, String operatorName, String notes) {
            auditDedupKeys.add(dedupKey);
        }
    }

    private static final class FakeReplayPublisher implements DlqReplayPublisher {
        private final List<String> published = new ArrayList<>();

        @Override
        public void publish(DlqEvent event, String outputTopic) {
            published.add(outputTopic + "|" + event.dedupKey());
        }
    }
}
