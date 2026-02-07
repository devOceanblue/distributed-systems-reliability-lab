package com.reliabilitylab.consumerservice.app;

import com.reliabilitylab.consumerservice.config.ConsumerServiceProperties;
import com.reliabilitylab.consumerservice.infra.ConsumerJdbcRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ConsumerTxHandlerTest {

    @Mock
    private ConsumerJdbcRepository consumerJdbcRepository;

    @Mock
    private ProjectionCacheInvalidator projectionCacheInvalidator;

    @Test
    void shouldInvalidateCacheAfterProjectionApplied() {
        ConsumerTxHandler txHandler = new ConsumerTxHandler(consumerJdbcRepository, projectionCacheInvalidator);
        when(consumerJdbcRepository.tryInsertProcessed(anyString(), anyString(), anyString(), anyInt(), anyLong()))
                .thenReturn(true);

        ProcessOutcome outcome = txHandler.apply(
                new ProcessingInput("evt-1", "tx-1", "AccountBalanceChanged", "A-1", 100, "{}", "main", 0, 1, 0),
                "consumer-service",
                ConsumerServiceProperties.IdempotencyMode.PROCESSED_TABLE,
                ""
        );

        assertEquals(ProcessOutcome.PROCESSED, outcome);
        verify(consumerJdbcRepository).applyProjectionDelta("A-1", 100);
        verify(projectionCacheInvalidator).invalidate("A-1");
    }

    @Test
    void shouldSkipInvalidationWhenDuplicateSkipped() {
        ConsumerTxHandler txHandler = new ConsumerTxHandler(consumerJdbcRepository, projectionCacheInvalidator);
        when(consumerJdbcRepository.tryInsertProcessed(anyString(), anyString(), anyString(), anyInt(), anyLong()))
                .thenReturn(false);

        ProcessOutcome outcome = txHandler.apply(
                new ProcessingInput("evt-1", "tx-1", "AccountBalanceChanged", "A-1", 100, "{}", "main", 0, 1, 0),
                "consumer-service",
                ConsumerServiceProperties.IdempotencyMode.PROCESSED_TABLE,
                ""
        );

        assertEquals(ProcessOutcome.DUPLICATE_SKIPPED, outcome);
        verify(consumerJdbcRepository, never()).applyProjectionDelta(anyString(), anyLong());
        verify(projectionCacheInvalidator, never()).invalidate(anyString());
    }

    @Test
    void shouldThrowPermanentErrorBeforeProjectionWrite() {
        ConsumerTxHandler txHandler = new ConsumerTxHandler(consumerJdbcRepository, projectionCacheInvalidator);

        PermanentProcessingException ex = assertThrows(PermanentProcessingException.class, () -> txHandler.apply(
                new ProcessingInput("evt-1", "tx-1", "AccountBalanceChanged", "A-2", 100, "{}", "main", 0, 1, 0),
                "consumer-service",
                ConsumerServiceProperties.IdempotencyMode.PROCESSED_TABLE,
                "A-2"
        ));

        assertEquals("forced permanent error for account=A-2", ex.getMessage());
        verify(consumerJdbcRepository, never()).applyProjectionDelta(anyString(), anyLong());
        verify(projectionCacheInvalidator, never()).invalidate(anyString());
    }
}
