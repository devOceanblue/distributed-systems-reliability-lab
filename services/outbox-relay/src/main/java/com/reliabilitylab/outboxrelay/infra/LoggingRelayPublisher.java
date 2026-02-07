package com.reliabilitylab.outboxrelay.infra;

import com.reliabilitylab.outboxrelay.app.OutboxEventRow;
import com.reliabilitylab.outboxrelay.app.RelayPublisher;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "false", matchIfMissing = true)
public class LoggingRelayPublisher implements RelayPublisher {
    private static final Logger log = LoggerFactory.getLogger(LoggingRelayPublisher.class);

    @Override
    public void publish(OutboxEventRow row) {
        log.info("[relay] publish skipped because app.kafka.enabled=false id={} dedupKey={}", row.id(), row.dedupKey());
    }
}
