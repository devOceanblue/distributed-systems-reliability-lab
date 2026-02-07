package com.reliabilitylab.commandservice.infra;

import com.reliabilitylab.eventcore.EventEnvelope;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "false", matchIfMissing = true)
public class LoggingBalanceEventPublisher implements BalanceEventPublisher {
    private static final Logger log = LoggerFactory.getLogger(LoggingBalanceEventPublisher.class);

    @Override
    public void publish(EventEnvelope envelope, String accountId) {
        log.info("[direct-mode] publish skipped because app.kafka.enabled=false accountId={} dedupKey={} eventType={}",
                accountId,
                envelope.dedupKey(),
                envelope.eventType());
    }
}
