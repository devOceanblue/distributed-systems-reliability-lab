package com.reliabilitylab.outboxrelay.app;

import com.reliabilitylab.outboxrelay.config.RelayProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class OutboxRelayScheduler {
    private static final Logger log = LoggerFactory.getLogger(OutboxRelayScheduler.class);

    private final OutboxRelayService outboxRelayService;
    private final RelayProperties relayProperties;

    public OutboxRelayScheduler(OutboxRelayService outboxRelayService, RelayProperties relayProperties) {
        this.outboxRelayService = outboxRelayService;
        this.relayProperties = relayProperties;
    }

    @Scheduled(fixedDelayString = "${app.relay.scheduler-delay-ms:1000}")
    public void run() {
        if (!relayProperties.isSchedulerEnabled()) {
            return;
        }

        try {
            outboxRelayService.runOnce();
        } catch (RuntimeException ex) {
            log.warn("relay cycle failed: {}", ex.getMessage());
        }
    }
}
