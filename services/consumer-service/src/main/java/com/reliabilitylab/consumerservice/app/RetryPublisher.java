package com.reliabilitylab.consumerservice.app;

public interface RetryPublisher {
    void publish(ProcessingInput input, Exception exception);
}
