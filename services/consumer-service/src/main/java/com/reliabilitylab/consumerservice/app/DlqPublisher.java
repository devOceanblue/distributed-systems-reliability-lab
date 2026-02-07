package com.reliabilitylab.consumerservice.app;

public interface DlqPublisher {
    void publish(ProcessingInput input, Exception exception);
}
