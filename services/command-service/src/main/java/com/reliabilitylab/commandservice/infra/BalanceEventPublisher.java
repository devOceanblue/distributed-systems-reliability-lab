package com.reliabilitylab.commandservice.infra;

import com.reliabilitylab.eventcore.EventEnvelope;

public interface BalanceEventPublisher {
    void publish(EventEnvelope envelope, String accountId);
}
