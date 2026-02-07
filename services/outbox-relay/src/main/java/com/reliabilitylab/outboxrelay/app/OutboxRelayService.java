package com.reliabilitylab.outboxrelay.app;

import com.reliabilitylab.outboxrelay.config.RelayProperties;
import com.reliabilitylab.outboxrelay.infra.OutboxEventRepository;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Instant;
import java.util.Optional;

@Service
public class OutboxRelayService {
    private final OutboxEventRepository outboxEventRepository;
    private final RelayPublisher relayPublisher;
    private final RelayFailpointGuard relayFailpointGuard;
    private final RelayProperties relayProperties;
    private final Clock clock;

    public OutboxRelayService(OutboxEventRepository outboxEventRepository,
                              RelayPublisher relayPublisher,
                              RelayFailpointGuard relayFailpointGuard,
                              RelayProperties relayProperties,
                              Clock clock) {
        this.outboxEventRepository = outboxEventRepository;
        this.relayPublisher = relayPublisher;
        this.relayFailpointGuard = relayFailpointGuard;
        this.relayProperties = relayProperties;
        this.clock = clock;
    }

    public RelayRunResult runOnce() {
        Optional<OutboxEventRow> locked = outboxEventRepository.lockAndMarkSending(relayProperties.getLockingMode());
        if (locked.isEmpty()) {
            return RelayRunResult.idle();
        }

        OutboxEventRow row = locked.get();
        try {
            relayFailpointGuard.check("FAILPOINT_BEFORE_KAFKA_SEND");
            relayPublisher.publish(row);
            relayFailpointGuard.check("FAILPOINT_AFTER_KAFKA_SEND_BEFORE_MARK_SENT");
            outboxEventRepository.markSent(row.id());
            return RelayRunResult.sent(row);
        } catch (RuntimeException ex) {
            handleFailure(row, ex);
            throw ex;
        }
    }

    private void handleFailure(OutboxEventRow row, RuntimeException ex) {
        int nextAttempt = row.attempts() + 1;
        if (nextAttempt >= relayProperties.getMaxAttempts()) {
            outboxEventRepository.markFailed(row.id(), nextAttempt, truncate(ex));
            return;
        }

        Instant nextAttemptAt = Instant.now(clock).plus(relayProperties.backoffForAttempt(nextAttempt));
        outboxEventRepository.reschedule(row.id(), nextAttempt, nextAttemptAt, truncate(ex));
    }

    private String truncate(Throwable throwable) {
        String message = throwable.getMessage();
        if (message == null) {
            return throwable.getClass().getSimpleName();
        }
        if (message.length() <= 500) {
            return message;
        }
        return message.substring(0, 500);
    }
}
