package com.reliabilitylab.consumerservice.app;

public interface ConsumerFailpointGuard {
    void check(String envName);
}
