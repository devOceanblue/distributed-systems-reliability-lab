package com.reliabilitylab.commandservice.app;

import com.reliabilitylab.commandservice.config.CommandServiceProperties;
import com.reliabilitylab.eventcore.EventEnvelope;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CommandApplicationServiceTest {

    @Mock
    private CommandTxHandler commandTxHandler;

    @Mock
    private com.reliabilitylab.commandservice.infra.BalanceEventPublisher balanceEventPublisher;

    @Mock
    private FailpointGuard failpointGuard;

    private CommandServiceProperties properties;

    @BeforeEach
    void setUp() {
        properties = new CommandServiceProperties();
    }

    @Test
    void shouldWriteOutboxOnlyInOutboxMode() {
        properties.setProduceMode(CommandServiceProperties.ProduceMode.OUTBOX);

        CommandApplicationService service = new CommandApplicationService(
                commandTxHandler,
                balanceEventPublisher,
                properties,
                failpointGuard
        );

        when(commandTxHandler.apply(eq("A-1"), eq("tx-1"), eq(100L), eq("trace-1"), eq(true)))
                .thenReturn(new CommandTxResult(100L, envelope("tx-1", 100L)));

        service.deposit("A-1", "tx-1", 100L, "trace-1");

        verify(commandTxHandler).apply("A-1", "tx-1", 100L, "trace-1", true);
        verify(balanceEventPublisher, never()).publish(any(), any());
        verify(failpointGuard, never()).check(any());
    }

    @Test
    void shouldPublishAfterCommitInDirectMode() {
        properties.setProduceMode(CommandServiceProperties.ProduceMode.DIRECT);

        CommandApplicationService service = new CommandApplicationService(
                commandTxHandler,
                balanceEventPublisher,
                properties,
                failpointGuard
        );

        EventEnvelope envelope = envelope("tx-2", 100L);
        when(commandTxHandler.apply(eq("A-1"), eq("tx-2"), eq(100L), eq("trace-2"), eq(false)))
                .thenReturn(new CommandTxResult(100L, envelope));

        service.deposit("A-1", "tx-2", 100L, "trace-2");

        verify(commandTxHandler).apply("A-1", "tx-2", 100L, "trace-2", false);
        verify(failpointGuard).check("FAILPOINT_AFTER_DB_COMMIT_BEFORE_KAFKA_SEND");
        verify(balanceEventPublisher).publish(envelope, "A-1");
    }

    private EventEnvelope envelope(String txId, long amount) {
        return new EventEnvelope(
                "evt-" + txId,
                txId,
                "AccountBalanceChanged",
                1,
                1L,
                "trace",
                "{\"amount\":" + amount + "}"
        );
    }
}
