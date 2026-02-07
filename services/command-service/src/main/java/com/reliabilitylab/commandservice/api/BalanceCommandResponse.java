package com.reliabilitylab.commandservice.api;

public record BalanceCommandResponse(
        String accountId,
        String txId,
        long amount,
        long balance,
        String produceMode,
        String status
) {
}
