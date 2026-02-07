package com.reliabilitylab.outboxrelay.app;

public interface RelayPublisher {
    void publish(OutboxEventRow row);
}
