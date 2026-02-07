package com.reliabilitylab.replayworker.app;

import java.util.List;

public interface DlqEventStore {
    void insertCapturedEvent(CapturedDlqEvent event);

    List<DlqEvent> findPending(ReplayRunCommand command);

    void markReplayed(long id);

    void markSkipped(long id, String reason);

    void insertReplayAudit(String dedupKey, String operatorName, String notes);
}
