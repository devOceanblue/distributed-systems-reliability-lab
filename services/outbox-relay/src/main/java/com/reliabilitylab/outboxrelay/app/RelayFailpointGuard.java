package com.reliabilitylab.outboxrelay.app;

public interface RelayFailpointGuard {
    void check(String envName);
}
