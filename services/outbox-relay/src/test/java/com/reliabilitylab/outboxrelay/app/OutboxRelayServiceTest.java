package com.reliabilitylab.outboxrelay.app;

import com.reliabilitylab.outboxrelay.config.RelayProperties;
import com.reliabilitylab.outboxrelay.infra.OutboxEventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OutboxRelayServiceTest {

    @Mock
    private OutboxEventRepository outboxEventRepository;

    @Mock
    private RelayPublisher relayPublisher;

    @Mock
    private RelayFailpointGuard relayFailpointGuard;

    private RelayProperties relayProperties;

    @BeforeEach
    void setUp() {
        relayProperties = new RelayProperties();
        relayProperties.setMaxAttempts(5);
    }

    @Test
    void shouldMarkSentWhenPublishSucceeds() {
        OutboxRelayService service = new OutboxRelayService(
                outboxEventRepository,
                relayPublisher,
                relayFailpointGuard,
                relayProperties,
                Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC)
        );

        OutboxEventRow row = new OutboxEventRow(1L, "evt-1", "tx-1", "AccountBalanceChanged", "{}", 0);
        when(outboxEventRepository.lockAndMarkSending(RelayProperties.LockingMode.SKIP_LOCKED)).thenReturn(Optional.of(row));

        RelayRunResult result = service.runOnce();

        assertEquals("SENT", result.state());
        verify(relayPublisher).publish(row);
        verify(outboxEventRepository).markSent(1L);
    }

    @Test
    void shouldRescheduleOnPublishError() {
        OutboxRelayService service = new OutboxRelayService(
                outboxEventRepository,
                relayPublisher,
                relayFailpointGuard,
                relayProperties,
                Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC)
        );

        OutboxEventRow row = new OutboxEventRow(1L, "evt-1", "tx-1", "AccountBalanceChanged", "{}", 0);
        when(outboxEventRepository.lockAndMarkSending(RelayProperties.LockingMode.SKIP_LOCKED)).thenReturn(Optional.of(row));
        RuntimeException error = new RuntimeException("publish failed");
        doThrow(error).when(relayPublisher).publish(row);

        assertThrows(RuntimeException.class, service::runOnce);
        verify(outboxEventRepository).reschedule(eq(1L), eq(1), any(), eq("publish failed"));
    }
}
