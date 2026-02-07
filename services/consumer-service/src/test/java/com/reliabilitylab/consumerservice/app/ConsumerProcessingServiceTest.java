package com.reliabilitylab.consumerservice.app;

import com.reliabilitylab.consumerservice.config.ConsumerServiceProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ConsumerProcessingServiceTest {

    @Mock
    private ConsumerTxHandler consumerTxHandler;

    @Mock
    private ConsumerFailpointGuard consumerFailpointGuard;

    @Mock
    private DlqPublisher dlqPublisher;

    @Mock
    private RetryPublisher retryPublisher;

    private ConsumerServiceProperties properties;

    @BeforeEach
    void setUp() {
        properties = new ConsumerServiceProperties();
    }

    @Test
    void shouldCommitAfterDbInAfterDbMode() {
        properties.setOffsetCommitMode(ConsumerServiceProperties.OffsetCommitMode.AFTER_DB);
        ConsumerProcessingService service = new ConsumerProcessingService(
                properties,
                consumerTxHandler,
                consumerFailpointGuard,
                dlqPublisher,
                retryPublisher
        );

        ProcessingInput input = new ProcessingInput("evt-1", "tx-1", "AccountBalanceChanged", "A-1", 100, "{}", "main", 0, 1, 0);
        when(consumerTxHandler.apply(any(), any(), any(), any())).thenReturn(ProcessOutcome.PROCESSED);

        final int[] commits = new int[]{0};
        ProcessOutcome outcome = service.consume(input, () -> commits[0]++);

        assertEquals(ProcessOutcome.PROCESSED, outcome);
        assertEquals(1, commits[0]);
    }

    @Test
    void shouldRoutePermanentErrorToDlq() {
        properties.setOffsetCommitMode(ConsumerServiceProperties.OffsetCommitMode.AFTER_DB);
        ConsumerProcessingService service = new ConsumerProcessingService(
                properties,
                consumerTxHandler,
                consumerFailpointGuard,
                dlqPublisher,
                retryPublisher
        );

        ProcessingInput input = new ProcessingInput("evt-1", "tx-1", "AccountBalanceChanged", "A-1", 100, "{}", "main", 0, 1, 0);
        when(consumerTxHandler.apply(any(), any(), any(), any()))
                .thenThrow(new PermanentProcessingException("permanent"));

        ProcessOutcome outcome = service.consume(input, () -> {
        });

        assertEquals(ProcessOutcome.DLQ, outcome);
        verify(dlqPublisher).publish(any(), any());
        verify(retryPublisher, never()).publish(any(), any());
    }
}
