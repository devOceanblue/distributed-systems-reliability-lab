package com.reliabilitylab.commandservice.app;

public interface FailpointGuard {
    void check(String envName);
}
