package com.reliabilitylab.eventcore;

public class FailpointTriggeredException extends RuntimeException {
    public FailpointTriggeredException(String message) {
        super(message);
    }
}
