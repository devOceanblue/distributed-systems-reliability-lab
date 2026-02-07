package com.reliabilitylab.replayworker.app;

public interface DlqReplayPublisher {
    void publish(DlqEvent event, String outputTopic);
}
