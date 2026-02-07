package com.reliabilitylab.commandservice.app;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.reliabilitylab.commandservice.infra.CommandJdbcRepository;
import com.reliabilitylab.eventcore.EventEnvelope;
import com.reliabilitylab.eventcore.EventEnvelopeBuilder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Component
public class CommandTxHandler {
    private final CommandJdbcRepository commandJdbcRepository;
    private final EventEnvelopeBuilder eventEnvelopeBuilder;
    private final ObjectMapper objectMapper;

    public CommandTxHandler(CommandJdbcRepository commandJdbcRepository,
                            EventEnvelopeBuilder eventEnvelopeBuilder,
                            ObjectMapper objectMapper) {
        this.commandJdbcRepository = commandJdbcRepository;
        this.eventEnvelopeBuilder = eventEnvelopeBuilder;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public CommandTxResult apply(String accountId, String txId, long amount, String traceId, boolean writeOutbox) {
        String payload = serializePayload(accountId, txId, amount);
        EventEnvelope envelope = eventEnvelopeBuilder.newEnvelope(
                txId,
                "AccountBalanceChanged",
                1,
                traceId,
                payload
        );

        long newBalance = commandJdbcRepository.applyDomainChange(accountId, txId, amount);

        if (writeOutbox) {
            commandJdbcRepository.insertOutbox(envelope);
        }

        return new CommandTxResult(newBalance, envelope);
    }

    private String serializePayload(String accountId, String txId, long amount) {
        try {
            return objectMapper.writeValueAsString(Map.of(
                    "accountId", accountId,
                    "txId", txId,
                    "amount", amount
            ));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("failed to serialize payload", e);
        }
    }
}
